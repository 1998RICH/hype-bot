import SwiftUI

/// Full-screen celebration when a like turns out to be mutual.
struct MatchOverlayView: View {
    @EnvironmentObject private var app: AppState
    let match: Match

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            Circle()
                .fill(Theme.glow(Theme.orange, radius: 280))
                .frame(width: 620, height: 620)
                .offset(y: -190)
            Circle()
                .fill(Theme.glow(Theme.violet, radius: 240))
                .frame(width: 520, height: 520)
                .offset(y: 300)
            VStack(spacing: 20) {
                Spacer()
                HStack(spacing: -18) {
                    AvatarView(profile: app.me, size: 110)
                        .overlay(Circle().stroke(Theme.accent, lineWidth: 4))
                    AvatarView(profile: match.crossing.profile, size: 110)
                        .overlay(Circle().stroke(Theme.accent, lineWidth: 4))
                }
                (Text("It's a ").foregroundColor(.white)
                 + Text("Run-In!").foregroundColor(Theme.accent))
                    .font(.system(size: 40, weight: .black, design: .rounded))
                Text("You and \(match.crossing.profile.firstName) crossed paths on \(match.crossing.routeName) — and you both liked what you saw.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.slate)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                Spacer()
                VoltButton(title: "Say hi 👋") {
                    app.newMatch = nil
                }
                Button("Keep browsing") {
                    app.newMatch = nil
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.slate)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
    }
}
