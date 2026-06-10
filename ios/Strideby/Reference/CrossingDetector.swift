import Foundation

/// Reference implementation of crossing detection.
///
/// In production this runs on the BACKEND, not on the phone: every synced run
/// uploads its GPS track, and the server compares tracks that overlap in time
/// and space. This is exactly how Strava's "grouped activities" / Flyby
/// feature works — no Bluetooth is involved, and only people who are on the
/// platform can be detected. It lives here in Swift so the logic is easy to
/// read and unit-test before porting to the server.
struct GPSSample {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
}

enum CrossingDetector {
    /// Seconds during which two runners were within `radiusMeters` of each
    /// other at (approximately) the same moment. Assumes both tracks are
    /// sorted by timestamp and sampled at ~1 Hz, which is what sport watches
    /// record.
    static func overlapSeconds(_ a: [GPSSample], _ b: [GPSSample],
                               radiusMeters: Double = 25,
                               timeToleranceSeconds: TimeInterval = 5) -> TimeInterval {
        guard !a.isEmpty, !b.isEmpty else { return 0 }
        var overlap: TimeInterval = 0
        var j = 0
        for sample in a {
            // Advance j to the b-sample closest in time to `sample`.
            while j + 1 < b.count,
                  abs(b[j + 1].timestamp.timeIntervalSince(sample.timestamp))
                    < abs(b[j].timestamp.timeIntervalSince(sample.timestamp)) {
                j += 1
            }
            let candidate = b[j]
            guard abs(candidate.timestamp.timeIntervalSince(sample.timestamp))
                    <= timeToleranceSeconds else { continue }
            if distanceMeters(sample, candidate) <= radiusMeters {
                overlap += 1
            }
        }
        return overlap
    }

    /// A "crossing" worth surfacing: at least `minOverlapSeconds` of shared
    /// path. 5 s counts a genuine face-to-face pass (~8 s within 25 m at
    /// running speeds). Measured in both directions and the smaller value
    /// wins — a real pass is symmetric, a single stray GPS point isn't.
    static func isCrossing(_ a: [GPSSample], _ b: [GPSSample],
                           minOverlapSeconds: TimeInterval = 5) -> Bool {
        min(overlapSeconds(a, b), overlapSeconds(b, a)) >= minOverlapSeconds
    }

    /// Haversine distance between two GPS samples, in meters.
    static func distanceMeters(_ a: GPSSample, _ b: GPSSample) -> Double {
        let earthRadius = 6_371_000.0
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let dLat = lat2 - lat1
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let h = sin(dLat / 2) * sin(dLat / 2)
              + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * earthRadius * asin(min(1, sqrt(h)))
    }
}
