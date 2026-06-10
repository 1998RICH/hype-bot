import CoreLocation
import Foundation
import HealthKit

/// Reads running workouts and their GPS routes from HealthKit — this is how
/// Apple Watch runs reach the Strideby backend. Requires the HealthKit
/// capability and an NSHealthShareUsageDescription (configured in
/// ios/project.yml; for a hand-made Xcode project add them in
/// Signing & Capabilities and the Info tab).
final class HealthKitManager {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async throws {
        let read: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute(),
        ]
        try await store.requestAuthorization(toShare: [], read: read)
    }

    /// Running workouts started after `since` (capped at the last 14 days),
    /// oldest first so crossings appear in chronological order.
    func runningWorkouts(since: Date?) async throws -> [HKWorkout] {
        let floor = Calendar.current.date(byAdding: .day, value: -14, to: .now)!
        let start = max(since ?? .distantPast, floor)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            HKQuery.predicateForWorkouts(with: .running),
            HKQuery.predicateForSamples(withStart: start, end: nil,
                                        options: .strictStartDate),
        ])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                    ascending: true)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: .workoutType(),
                                      predicate: predicate,
                                      limit: 20,
                                      sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
                }
            }
            store.execute(query)
        }
    }

    /// The workout's GPS track as upload-ready points. Empty when the
    /// workout has no route (e.g. treadmill runs).
    func routePoints(for workout: HKWorkout) async throws -> [APIClient.GPSPoint] {
        guard let route = try await workoutRoute(for: workout) else { return [] }
        return try await locations(for: route).map {
            APIClient.GPSPoint(lat: $0.coordinate.latitude,
                               lon: $0.coordinate.longitude,
                               t: $0.timestamp.timeIntervalSince1970)
        }
    }

    private func workoutRoute(for workout: HKWorkout) async throws -> HKWorkoutRoute? {
        let predicate = HKQuery.predicateForObjects(from: workout)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: HKSeriesType.workoutRoute(),
                                      predicate: predicate,
                                      limit: 1,
                                      sortDescriptors: nil) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples?.first as? HKWorkoutRoute)
                }
            }
            store.execute(query)
        }
    }

    private func locations(for route: HKWorkoutRoute) async throws -> [CLLocation] {
        try await withCheckedThrowingContinuation { continuation in
            var all: [CLLocation] = []
            let query = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                all.append(contentsOf: locations ?? [])
                if done {
                    continuation.resume(returning: all)
                }
            }
            store.execute(query)
        }
    }
}
