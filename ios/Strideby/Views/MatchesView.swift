import SwiftUI

struct MatchesView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    (Text("Your ").foregroundColor(.white)
                     + Text("matches").foregroundColor(Theme.accent))
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .padding(.top, 8)
                    if app.matches.isEmpty {
                        emptyState
                            .frame(maxWidth: .infinity)
                            .padding(.top, 90)
                    }
                    ForEach(app.matches) { match in
                        NavigationLink(value: match.id) {
                            row(match)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { id in
                ChatView(matchID: id)
            }
            .refreshable { await app.refresh() }
        }
    }

    private func row(_ match: Match) -> some View {
        HStack(spacing: 12) {
            AvatarView(profile: match.crossing.profile, size: 54)
                .overlay(Circle().stroke(Theme.accent.opacity(0.6), lineWidth: 2))
            VStack(alignment: .leading, spacing: 3) {
                Text(match.crossing.profile.firstName)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(match.messages.last?.text
                     ?? "You crossed on \(match.crossing.routeName) — say hi!")
                    .font(.subheadline)
                    .foregroundStyle(Theme.slate)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.slate)
        }
        .padding(14)
        .glassCard(radius: 20)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 44))
                .foregroundStyle(Theme.accent)
            Text("No matches yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Text("Like the runners you cross — when it's mutual, they show up here.")
                .font(.subheadline)
                .foregroundStyle(Theme.slate)
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }
}
