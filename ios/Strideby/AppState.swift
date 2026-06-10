import SwiftUI

/// Single source of truth for the prototype. In production this splits into
/// services backed by a real server (crossings feed, matches, chat) — see
/// docs/ARCHITECTURE.md.
final class AppState: ObservableObject {
    @Published var hasOnboarded = false
    @Published var me = MockData.me
    @Published var appleWatchConnected = false
    @Published var garminConnected = false

    /// Crossings you haven't liked or passed on yet.
    @Published var pendingCrossings: [Crossing] = MockData.crossings
    @Published var matches: [Match] = MockData.seedMatches
    /// Non-nil while the "It's a Run-In!" overlay is showing.
    @Published var newMatch: Match?

    func like(_ crossing: Crossing) {
        pendingCrossings.removeAll { $0.id == crossing.id }
        guard crossing.profile.likesYou else { return }
        let match = Match(id: UUID(), crossing: crossing, messages: [], matchedAt: .now)
        matches.insert(match, at: 0)
        newMatch = match
    }

    func pass(_ crossing: Crossing) {
        pendingCrossings.removeAll { $0.id == crossing.id }
    }

    /// Demo helper: pretend a fresh run just synced from the watch.
    func syncDemoRun() {
        pendingCrossings = MockData.crossings
    }

    func send(_ text: String, in matchID: UUID) {
        guard let index = matches.firstIndex(where: { $0.id == matchID }) else { return }
        matches[index].messages.append(
            ChatMessage(id: UUID(), sender: .me, text: text, date: .now)
        )
        scheduleDemoReply(for: matchID)
    }

    /// Demo-only: canned replies so chat feels alive without a backend.
    private func scheduleDemoReply(for matchID: UUID) {
        let replies = [
            "Ha! I was wondering who flew past me 😄",
            "Sunrise on that loop is unbeatable, right?",
            "I'm in. Loser buys the post-run coffee ☕️",
            "Deal — same spot, Saturday 8am?"
        ]
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in
            guard let self,
                  let index = self.matches.firstIndex(where: { $0.id == matchID })
            else { return }
            let reply = replies[self.matches[index].messages.count % replies.count]
            self.matches[index].messages.append(
                ChatMessage(id: UUID(), sender: .them, text: reply, date: .now)
            )
        }
    }
}
