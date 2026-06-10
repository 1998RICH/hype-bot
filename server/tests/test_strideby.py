"""Tests for crossing detection and the full API flow.

Run from the server/ directory:  pytest
"""
import os
import pathlib

os.environ["DATABASE_URL"] = "sqlite:///./test_strideby.db"

import pytest
from fastapi.testclient import TestClient

from app import detection
from app.db import engine
from app.main import app

T0 = 1_750_000_000.0  # fixed epoch so tests are deterministic
LAT0, LON0 = 40.0, -73.97
M_PER_DEG_LAT = 111_320.0
M_PER_DEG_LON = M_PER_DEG_LAT * 0.766  # cos(40°)


def northbound(duration_s=600, speed=3.0, t0=T0, lon_offset_m=0.0):
    """A runner heading straight north at `speed` m/s, one sample per second."""
    lon = LON0 + lon_offset_m / M_PER_DEG_LON
    return [(LAT0 + speed * i / M_PER_DEG_LAT, lon, t0 + i)
            for i in range(int(duration_s))]


def southbound(duration_s=600, speed=3.0, t0=T0):
    """Starts 1800 m north of LAT0 and runs south — passes the northbound
    runner briefly, exactly like the false 'ran with' the Strava user saw."""
    start_lat = LAT0 + 1800.0 / M_PER_DEG_LAT
    return [(start_lat - speed * i / M_PER_DEG_LAT, LON0, t0 + i)
            for i in range(int(duration_s))]


# --- detector unit tests ------------------------------------------------------

def test_same_path_same_time_is_full_overlap():
    stats = detection.overlap_stats(northbound(), northbound())
    assert stats.overlap_seconds >= 590
    assert stats.closest_meters < 1


def test_same_path_an_hour_apart_never_overlaps():
    stats = detection.overlap_stats(northbound(), northbound(t0=T0 + 3600))
    assert stats.overlap_seconds == 0


def test_parallel_streets_50m_apart_never_overlap():
    stats = detection.overlap_stats(northbound(), northbound(lon_offset_m=50))
    assert stats.overlap_seconds == 0
    assert 40 < stats.closest_meters < 60


def test_brief_opposite_direction_pass_counts_as_crossing():
    # Closing speed 6 m/s within a 25 m radius ≈ 8 s together — a genuine
    # face-to-face pass, which is exactly what the app is about.
    stats = detection.overlap_stats(northbound(), southbound())
    assert detection.MIN_OVERLAP_S <= stats.overlap_seconds < 15
    assert stats.closest_meters < 5


def test_single_blip_is_below_threshold():
    # One isolated second within radius (a GPS glitch) must not count.
    blip = [northbound()[300]]
    stats = detection.overlap_stats(northbound(), blip)
    assert stats.overlap_seconds < detection.MIN_OVERLAP_S


def test_home_zone_trim_removes_route_endpoints():
    track = northbound()
    trimmed = detection.trim_home_zone(track)
    assert 0 < len(trimmed) < len(track)
    start_gap = detection.haversine_m(trimmed[0][0], trimmed[0][1],
                                      track[0][0], track[0][1])
    end_gap = detection.haversine_m(trimmed[-1][0], trimmed[-1][1],
                                    track[-1][0], track[-1][1])
    assert start_gap >= detection.HOME_ZONE_M
    assert end_gap >= detection.HOME_ZONE_M


def test_pace_string():
    assert detection.pace_str(1000, 295) == "4:55 /km"
    assert detection.pace_str(0, 300) == ""


# --- API flow tests -----------------------------------------------------------

@pytest.fixture()
def client():
    engine.dispose()
    db_file = pathlib.Path("test_strideby.db")
    db_file.unlink(missing_ok=True)
    with TestClient(app) as c:
        yield c
    engine.dispose()
    db_file.unlink(missing_ok=True)


def register(client, email, name):
    response = client.post("/auth/register", json={
        "email": email, "password": "password123",
        "first_name": name, "age": 28,
    })
    assert response.status_code == 200, response.text
    return response.json()["token"]


def auth(token):
    return {"Authorization": f"Bearer {token}"}


def run_body(track):
    return {"samples": [{"lat": lat, "lon": lon, "t": t}
                        for lat, lon, t in track]}


def test_full_flow_upload_cross_match_chat(client):
    alice = register(client, "alice@example.com", "Alice")
    bob = register(client, "bob@example.com", "Bob")

    # Alice runs first — nobody to cross yet.
    response = client.post("/runs", json=run_body(northbound()),
                           headers=auth(alice))
    assert response.status_code == 200
    assert response.json()["new_crossings"] == 0

    # Bob runs the same route at the same time — crossing detected.
    response = client.post("/runs", json=run_body(northbound()),
                           headers=auth(bob))
    assert response.json()["new_crossings"] == 1

    # Both see each other in their feed.
    alice_feed = client.get("/crossings", headers=auth(alice)).json()
    bob_feed = client.get("/crossings", headers=auth(bob)).json()
    assert len(alice_feed) == 1 and len(bob_feed) == 1
    assert alice_feed[0]["profile"]["first_name"] == "Bob"
    assert bob_feed[0]["profile"]["first_name"] == "Alice"
    assert alice_feed[0]["overlap_minutes"] >= 1
    assert alice_feed[0]["their_pace"] != ""

    # Alice likes first — no match yet. Bob likes back — match!
    response = client.post(f"/crossings/{alice_feed[0]['id']}/decision",
                           json={"liked": True}, headers=auth(alice))
    assert response.json()["matched"] is False
    response = client.post(f"/crossings/{bob_feed[0]['id']}/decision",
                           json={"liked": True}, headers=auth(bob))
    body = response.json()
    assert body["matched"] is True
    match_id = body["match"]["id"]
    assert body["match"]["profile"]["first_name"] == "Alice"

    # Both sides see the match.
    assert len(client.get("/matches", headers=auth(alice)).json()) == 1

    # Chat works in both directions.
    client.post(f"/matches/{match_id}/messages",
                json={"text": "So YOU'RE the one who out-kicked me!"},
                headers=auth(bob))
    messages = client.get(f"/matches/{match_id}/messages",
                          headers=auth(alice)).json()
    assert len(messages) == 1
    assert messages[0]["sender"] == "them"

    # Decided crossings leave the feed.
    assert client.get("/crossings", headers=auth(alice)).json() == []


def test_brief_pass_creates_a_crossing(client):
    register_token = register(client, "a@example.com", "A")
    passerby = register(client, "b@example.com", "B")

    client.post("/runs", json=run_body(northbound()), headers=auth(register_token))
    response = client.post("/runs", json=run_body(southbound()),
                           headers=auth(passerby))
    # ~8 seconds face to face in opposite directions — that's a crossing.
    assert response.json()["new_crossings"] == 1


def test_ghost_mode_blocks_crossings(client):
    ghost = register(client, "ghost@example.com", "Ghost")
    runner = register(client, "runner@example.com", "Runner")

    response = client.put("/me", json={"ghost_mode": True}, headers=auth(ghost))
    assert response.json()["ghost_mode"] is True

    client.post("/runs", json=run_body(northbound()), headers=auth(ghost))
    response = client.post("/runs", json=run_body(northbound()),
                           headers=auth(runner))
    assert response.json()["new_crossings"] == 0


def test_pass_means_no_match(client):
    alice = register(client, "a2@example.com", "Alice")
    bob = register(client, "b2@example.com", "Bob")
    client.post("/runs", json=run_body(northbound()), headers=auth(alice))
    client.post("/runs", json=run_body(northbound()), headers=auth(bob))

    alice_feed = client.get("/crossings", headers=auth(alice)).json()
    bob_feed = client.get("/crossings", headers=auth(bob)).json()
    client.post(f"/crossings/{alice_feed[0]['id']}/decision",
                json={"liked": False}, headers=auth(alice))
    response = client.post(f"/crossings/{bob_feed[0]['id']}/decision",
                           json={"liked": True}, headers=auth(bob))
    assert response.json()["matched"] is False
    assert client.get("/matches", headers=auth(bob)).json() == []


def test_auth_required(client):
    assert client.get("/crossings").status_code == 401
    assert client.get("/me", headers=auth("garbage-token")).status_code == 401
