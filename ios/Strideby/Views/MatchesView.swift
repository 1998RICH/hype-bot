import SwiftUI

struct MatchesView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        NavigationStack {
            Group {
                if app.matches.isEmpty {
                    emptyState
                } else {
                    List(app.matches) { match in
                        NavigationLink(value: match.id) { row(match) }
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.cloud)
            .navigationTitle("Matches")
            .navigationDestination(for: UUID.self) { id in
                ChatView(matchID: id)
            }
        }
    }

    private func row(_ match: Match) -> some View {
        HStack(spacing: 12) {
            AvatarView(profile: match.crossing.profile, size: 54)
            VStack(alignment: .leading, spacing: 3) {
                Text(match.crossing.profile.firstName)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text(match.messages.last?.text
                     ?? "You crossed on \(match.crossing.routeName) — say hi!")
                    .font(.subheadline)
                    .foregroundStyle(Theme.slate)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 44))
                .foregroundStyle(Theme.orange)
            Text("No matches yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.ink)
            Text("Like the runners you cross — when it's mutual, they show up here.")
                .font(.subheadline)
                .foregroundStyle(Theme.slate)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}
