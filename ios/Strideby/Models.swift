import SwiftUI

struct RunnerProfile: Identifiable {
    let id: UUID
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
    let id: UUID
    var profile: RunnerProfile
    var routeName: String
    var date: Date
    /// Minutes your tracks stayed within ~25 m of each other.
    var overlapMinutes: Int
    var closestDistanceMeters: Int
    var theirPace: String
}

struct ChatMessage: Identifiable {
    enum Sender: Equatable { case me, them }
    let id: UUID
    var sender: Sender
    var text: String
    var date: Date
}

struct Match: Identifiable {
    let id: UUID
    var crossing: Crossing
    var messages: [ChatMessage]
    var matchedAt: Date
}
