import SwiftUI

/// Full-screen celebration when a like turns out to be mutual.
struct MatchOverlayView: View {
    @EnvironmentObject private var app: AppState
    let match: Match

    var body: some View {
        ZStack {
            Theme.brandGradient.ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer()
                HStack(spacing: -18) {
                    AvatarView(profile: app.me, size: 110)
                        .overlay(Circle().stroke(.white, lineWidth: 4))
                    AvatarView(profile: match.crossing.profile, size: 110)
                        .overlay(Circle().stroke(.white, lineWidth: 4))
                }
                Text("It's a Run-In!")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("You and \(match.crossing.profile.firstName) crossed paths on \(match.crossing.routeName) — and you both liked what you saw.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                Spacer()
                Button {
                    app.newMatch = nil
                } label: {
                    Text("Say hi 👋")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(Theme.orange)
                }
                Button("Keep browsing") {
                    app.newMatch = nil
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
    }
}
