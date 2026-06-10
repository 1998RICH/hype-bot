"""Crossing detection — the Python port of ios/Strideby/Reference/CrossingDetector.swift.

Two runners "crossed" when their GPS tracks were within RADIUS_M of each
other at (approximately) the same moment for at least MIN_OVERLAP_S seconds.
At 5 s this counts a genuine face-to-face pass (two runners passing in
opposite directions stay within 25 m for ~8 s) while still filtering
single-sample GPS blips.
"""
import math
from dataclasses import dataclass

RADIUS_M = 25.0
TIME_TOL_S = 5.0
MIN_OVERLAP_S = 5.0
# Samples this close to a run's start/end point are discarded for users with
# hide_home_zone enabled, so crossings never reveal where someone lives.
HOME_ZONE_M = 400.0

Sample = tuple[float, float, float]  # (lat, lon, epoch_seconds)


@dataclass
class OverlapStats:
    overlap_seconds: float
    closest_meters: float
    occurred_at_epoch: float  # moment of the closest pass


def haversine_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    earth_radius = 6_371_000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dlat = p2 - p1
    dlon = math.radians(lon2 - lon1)
    h = (math.sin(dlat / 2) ** 2
         + math.cos(p1) * math.cos(p2) * math.sin(dlon / 2) ** 2)
    return 2 * earth_radius * math.asin(min(1.0, math.sqrt(h)))


def track_distance_m(samples: list[Sample]) -> float:
    return sum(
        haversine_m(a[0], a[1], b[0], b[1])
        for a, b in zip(samples, samples[1:])
    )


def trim_home_zone(samples: list[Sample], radius_m: float = HOME_ZONE_M) -> list[Sample]:
    """Drop the leading/trailing samples near the run's start/end points."""
    if len(samples) < 3:
        return []
    start, end = samples[0], samples[-1]
    i = 0
    while i < len(samples) and haversine_m(samples[i][0], samples[i][1], start[0], start[1]) < radius_m:
        i += 1
    j = len(samples) - 1
    while j >= 0 and haversine_m(samples[j][0], samples[j][1], end[0], end[1]) < radius_m:
        j -= 1
    return samples[i:j + 1] if i < j else []


def overlap_stats(a: list[Sample], b: list[Sample],
                  radius_m: float = RADIUS_M,
                  time_tol_s: float = TIME_TOL_S) -> OverlapStats:
    """Symmetric overlap between two tracks.

    Measured in both directions and the smaller value wins: a genuine pass
    is symmetric, while a single stray GPS point in one track can match
    many samples of the other within the time tolerance and inflate the
    one-directional count.
    """
    forward = _directed_stats(a, b, radius_m, time_tol_s)
    backward = _directed_stats(b, a, radius_m, time_tol_s)
    return OverlapStats(
        overlap_seconds=min(forward.overlap_seconds, backward.overlap_seconds),
        closest_meters=min(forward.closest_meters, backward.closest_meters),
        occurred_at_epoch=forward.occurred_at_epoch,
    )


def _directed_stats(a: list[Sample], b: list[Sample],
                    radius_m: float, time_tol_s: float) -> OverlapStats:
    """Walk track `a`; count seconds where the time-nearest sample of `b`
    is within radius. Assumes ~1 Hz sampling, which sport watches record.
    """
    if not a or not b:
        return OverlapStats(0.0, math.inf, 0.0)

    overlap = 0.0
    closest = math.inf
    occurred_at = a[0][2] if a else 0.0
    j = 0
    for lat, lon, t in a:
        while j + 1 < len(b) and abs(b[j + 1][2] - t) < abs(b[j][2] - t):
            j += 1
        blat, blon, bt = b[j]
        if abs(bt - t) > time_tol_s:
            continue
        d = haversine_m(lat, lon, blat, blon)
        if d < closest:
            closest = d
            occurred_at = t
        if d <= radius_m:
            overlap += 1.0
    return OverlapStats(overlap, closest, occurred_at)


def pace_str(distance_m: float, duration_s: float) -> str:
    """'4:55 /km' from raw distance and duration."""
    if distance_m < 50 or duration_s <= 0:
        return ""
    sec_per_km = duration_s / (distance_m / 1000.0)
    minutes, seconds = divmod(int(round(sec_per_km)), 60)
    return f"{minutes}:{seconds:02d} /km"
