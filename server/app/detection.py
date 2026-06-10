"""Crossing detection — the Python port of ios/Strideby/Reference/CrossingDetector.swift.

Two runners "crossed" when their GPS tracks were within RADIUS_M of each
other at (approximately) the same moment for at least MIN_OVERLAP_S seconds.
The minimum-overlap rule is what prevents false positives like a brief
drive-by or a single GPS blip.
"""
import math
from dataclasses import dataclass

RADIUS_M = 25.0
TIME_TOL_S = 5.0
MIN_OVERLAP_S = 60.0
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
    """Walk both time-sorted tracks; count seconds spent within radius.

    Assumes ~1 Hz sampling, which is what sport watches record.
    """
    if not a or not b:
        return OverlapStats(0.0, math.inf, 0.0)

    overlap = 0.0
    closest = math.inf
    occurred_at = a[0][2]
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
