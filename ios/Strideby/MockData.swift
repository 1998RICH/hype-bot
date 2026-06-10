import CoreLocation
import SwiftUI

/// Seed data so the prototype is fully explorable without a backend.
enum MockData {
    static var me = RunnerProfile(
        id: UUID().uuidString,
        firstName: "You",
        age: 28,
        bio: "Chasing a sub-20 5K and good coffee.",
        pacePerKm: "5:10 /km",
        weeklyKm: 32,
        favoriteDistance: "10K",
        tags: ["Morning runner", "Espresso", "Trail curious"],
        emoji: "🏃",
        avatarColors: [Theme.yellow, Theme.orange],
        likesYou: false
    )

    static var crossings: [Crossing] {
        [
            Crossing(
                id: UUID().uuidString,
                profile: RunnerProfile(
                    id: UUID().uuidString, firstName: "Lena", age: 27,
                    bio: "Half-marathon addict. I negative-split everything, including brunch.",
                    pacePerKm: "4:55 /km", weeklyKm: 45, favoriteDistance: "Half marathon",
                    tags: ["Sunrise runs", "Playlist curator", "Dog mom"],
                    emoji: "🏃‍♀️", avatarColors: [Color(hex: 0xFFB55C), Color(hex: 0xFC5200)],
                    likesYou: true
                ),
                routeName: "Riverside Loop", date: hoursAgo(3),
                overlapMinutes: 4, closestDistanceMeters: 6, theirPace: "4:55 /km"
            ),
            Crossing(
                id: UUID().uuidString,
                profile: RunnerProfile(
                    id: UUID().uuidString, firstName: "Marco", age: 31,
                    bio: "Trail runner pretending to like road races. Post-run pizza is non-negotiable.",
                    pacePerKm: "5:30 /km", weeklyKm: 38, favoriteDistance: "Trail 20K",
                    tags: ["Trails", "Pizza", "Strava addict"],
                    emoji: "🏃‍♂️", avatarColors: [Color(hex: 0xFFC629), Color(hex: 0xFF8A00)],
                    likesYou: false
                ),
                routeName: "Canal Path", date: hoursAgo(26),
                overlapMinutes: 7, closestDistanceMeters: 3, theirPace: "5:30 /km"
            ),
            Crossing(
                id: UUID().uuidString,
                profile: RunnerProfile(
                    id: UUID().uuidString, firstName: "Aki", age: 26,
                    bio: "Track nights on Tuesdays. Will judge your warm-up routine (lovingly).",
                    pacePerKm: "4:20 /km", weeklyKm: 55, favoriteDistance: "5K",
                    tags: ["Track nights", "Ramen", "Cat person"],
                    emoji: "🏃‍♀️", avatarColors: [Color(hex: 0xFF9D3C), Color(hex: 0xE6451B)],
                    likesYou: true
                ),
                routeName: "Stadium Park", date: hoursAgo(50),
                overlapMinutes: 2, closestDistanceMeters: 9, theirPace: "4:20 /km"
            ),
            Crossing(
                id: UUID().uuidString,
                profile: RunnerProfile(
                    id: UUID().uuidString, firstName: "June", age: 29,
                    bio: "Marathon #4 in October. Looking for someone to share long-run snacks with.",
                    pacePerKm: "5:45 /km", weeklyKm: 60, favoriteDistance: "Marathon",
                    tags: ["Long runs", "Gels & gummies", "Bookworm"],
                    emoji: "🏃‍♀️", avatarColors: [Color(hex: 0xFFD166), Color(hex: 0xFC5200)],
                    likesYou: true
                ),
                routeName: "Riverside Loop", date: hoursAgo(74),
                overlapMinutes: 11, closestDistanceMeters: 2, theirPace: "5:45 /km"
            ),
            Crossing(
                id: UUID().uuidString,
                profile: RunnerProfile(
                    id: UUID().uuidString, firstName: "Sam", age: 33,
                    bio: "Recovering cyclist. My watch has more PRs than my legs.",
                    pacePerKm: "5:05 /km", weeklyKm: 28, favoriteDistance: "10K",
                    tags: ["Garmin gang", "Coffee rides", "Early bird"],
                    emoji: "🏃‍♂️", avatarColors: [Color(hex: 0xFFB55C), Color(hex: 0xFF6B1A)],
                    likesYou: false
                ),
                routeName: "Harbor Front", date: hoursAgo(98),
                overlapMinutes: 5, closestDistanceMeters: 4, theirPace: "5:05 /km"
            )
        ]
    }

    static var seedMatches: [Match] {
        let noa = RunnerProfile(
            id: UUID().uuidString, firstName: "Noa", age: 25,
            bio: "Parkrun every Saturday, rain or shine.",
            pacePerKm: "5:20 /km", weeklyKm: 30, favoriteDistance: "5K",
            tags: ["Parkrun", "Baker", "Plant parent"],
            emoji: "🏃‍♀️", avatarColors: [Color(hex: 0xFFC629), Color(hex: 0xFC5200)],
            likesYou: true
        )
        let crossing = Crossing(
            id: UUID().uuidString, profile: noa,
            routeName: "Old Town 5K", date: hoursAgo(120),
            overlapMinutes: 9, closestDistanceMeters: 2, theirPace: "5:20 /km"
        )
        return [
            Match(
                id: UUID().uuidString,
                crossing: crossing,
                messages: [
                    ChatMessage(id: UUID().uuidString, sender: .them,
                                text: "So YOU'RE the one who out-kicked me at the finish 😄",
                                date: hoursAgo(28)),
                    ChatMessage(id: UUID().uuidString, sender: .me,
                                text: "Guilty. In my defense, I heard footsteps and panicked.",
                                date: hoursAgo(27)),
                    ChatMessage(id: UUID().uuidString, sender: .them,
                                text: "Rematch Saturday? Loser buys coffee.",
                                date: hoursAgo(26))
                ],
                matchedAt: hoursAgo(30)
            )
        ]
    }

    /// A smooth park-loop route for the demo run map.
    static func demoLoop(points: Int = 240) -> [CLLocationCoordinate2D] {
        (0..<points).map { index in
            let theta = 2 * Double.pi * Double(index) / Double(points)
            return CLLocationCoordinate2D(
                latitude: 40.7855 + 0.0042 * sin(theta),
                longitude: -73.9655 + 0.0061 * cos(theta)
            )
        }
    }

    static var demoRunDetails: [RunDetail] {
        let route = demoLoop()
        let feed = crossings
        return [
            RunDetail(
                summary: RunSummary(id: "demo-run-1", date: hoursAgo(20),
                                    distanceMeters: 5230, durationSeconds: 1684,
                                    crossingCount: 2),
                coordinates: route,
                crossed: [
                    CrossedRunner(id: "demo-crossed-1", profile: feed[0].profile,
                                  coordinate: route[40], overlapMinutes: 4),
                    CrossedRunner(id: "demo-crossed-2", profile: feed[3].profile,
                                  coordinate: route[150], overlapMinutes: 11),
                ]
            ),
            RunDetail(
                summary: RunSummary(id: "demo-run-2", date: hoursAgo(68),
                                    distanceMeters: 8140, durationSeconds: 2745,
                                    crossingCount: 0),
                coordinates: route,
                crossed: []
            ),
        ]
    }

    private static func hoursAgo(_ hours: Double) -> Date {
        Date.now.addingTimeInterval(-3600 * hours)
    }
}
