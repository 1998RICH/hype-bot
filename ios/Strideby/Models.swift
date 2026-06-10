import CoreLocation
import SwiftUI

struct RunnerProfile: Identifiable {
    // String ids everywhere: mock data uses UUID strings, the backend uses
    // numeric ids — both fit.
    let id: String
    var firstName: String
    var age: Int
    var bio: String
    var pacePerKm: String
    var weeklyKm: Int
    var favoriteDistance: String
    var tags: [String]
    /// Photo stand-in for the prototype; real app uses moderated photos.
    var emoji: String
    var avatarColors: [Color]
    /// Mock of the server-side "they already liked you" state.
    var likesYou: Bool
}

/// One detected path-crossing between you and another Strideby runner.
/// In production these are computed on the backend by comparing GPS tracks
/// of synced runs (same place, same time) — never via Bluetooth.
struct Crossing: Identifiable {
    let id: String
    var profile: RunnerProfile
    var routeName: String
    var date: Date
    /// Minutes your tracks stayed within ~25 m of each other.
    var overlapMinutes: Int
    var closestDistanceMeters: Int
    var theirPace: String
    /// Where the closest pass happened — the card's map hero.
    var coordinate: CLLocationCoordinate2D? = nil
}

struct ChatMessage: Identifiable {
    enum Sender: Equatable { case me, them }
    let id: String
    var sender: Sender
    var text: String
    var date: Date
}

struct Match: Identifiable {
    let id: String
    var crossing: Crossing
    var messages: [ChatMessage]
    var matchedAt: Date
}

/// One of your own recorded runs, as shown in the Run tab list.
struct RunSummary: Identifiable {
    let id: String
    var date: Date
    var distanceMeters: Double
    var durationSeconds: Double
    var crossingCount: Int

    var distanceText: String {
        String(format: "%.1f km", distanceMeters / 1000)
    }

    var durationText: String {
        let total = Int(durationSeconds)
        if total >= 3600 {
            return String(format: "%d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
        }
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    var paceText: String {
        guard distanceMeters > 50, durationSeconds > 0 else { return "–" }
        let secondsPerKm = durationSeconds / (distanceMeters / 1000)
        return String(format: "%d:%02d /km", Int(secondsPerKm) / 60, Int(secondsPerKm) % 60)
    }
}

/// A runner you crossed on a specific run, with where it happened.
struct CrossedRunner: Identifiable {
    let id: String
    var profile: RunnerProfile
    var coordinate: CLLocationCoordinate2D?
    var overlapMinutes: Int
}

struct RunDetail {
    var summary: RunSummary
    var coordinates: [CLLocationCoordinate2D]
    var crossed: [CrossedRunner]
}
