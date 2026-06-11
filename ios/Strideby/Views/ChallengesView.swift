import SwiftUI

/// Challenges — built 1:1 to the design spec: #050505 background, asymmetric
/// 3-card grid (radius 24), weekly progress tracker, leaderboard, gray CTA.
/// SF Pro (system), horizontal padding 20, vertical gap 16, no visible
/// borders, very light shadows.
struct ChallengesView: View {
    private let cardDark = Color(hex: 0x262626)
    private let cardDarker = Color(hex: 0x2F2F2F)
    private let progressBg = Color(hex: 0x242424)
    private let boardBg = Color(hex: 0x1F1F1F)
    private let lime = Color(hex: 0xB7FF4A)
    private let textSecondary = Color(hex: 0xBDBDBD)
    private let textMuted = Color(hex: 0x8A8A8A)

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Challenges")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
                challengeGrid
                progressCard
                leaderboardCard
                ctaButton
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .background(Color(hex: 0x050505).ignoresSafeArea())
    }

    // MARK: - Asymmetric challenge grid

    private var challengeGrid: some View {
        HStack(spacing: 16) {
            card1
            VStack(spacing: 16) {
                card2
                card3
            }
            .frame(width: 136)
        }
        .frame(height: 220)
    }

    private var card1: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Today's Challenge")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(lime)
            Text("3 Miles Running!")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
            Text("Challenge yourself today and reach a new peak.")
                .font(.system(size: 12))
                .foregroundStyle(textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                limePill("Easy")
                neutralPill("261 joined")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(cardDark)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
    }

    private var card2: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("40 Minutes!")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.black)
            Text("for 7 days")
                .font(.system(size: 12))
                .foregroundStyle(.black.opacity(0.65))
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                whitePill("Medium")
                outlinePill("14 joined")
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(lime)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: lime.opacity(0.18), radius: 8, y: 4)
    }

    private var card3: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Night Running Club")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                limePill("Easy")
                neutralPill("3 joined")
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(cardDarker)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
    }

    // MARK: - Weekly progress

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Your Challenge")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("Everyday 5 Miles Running")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(lime)
            }
            HStack {
                ForEach(Array(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].enumerated()),
                        id: \.offset) { index, day in
                    VStack(spacing: 7) {
                        Text(day)
                            .font(.system(size: 11))
                            .foregroundStyle(textMuted)
                        ZStack {
                            if index < 4 {
                                Circle().fill(lime)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            } else {
                                Circle()
                                    .strokeBorder(Color(hex: 0x4A4A4A), lineWidth: 1.5)
                            }
                        }
                        .frame(width: 27, height: 27)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(progressBg)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
    }

    // MARK: - Leaderboard

    private var leaderboardCard: some View {
        VStack(spacing: 16) {
            Text("Leaderboard")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 34) {
                boardProfile(medal: "🥇", name: "Emily Peter",
                             colors: [Color(hex: 0xF6C26B), Color(hex: 0xD96B3B)])
                boardProfile(medal: "🥈", name: "David White",
                             colors: [Color(hex: 0x8FB7F6), Color(hex: 0x4B6BD9)])
                boardProfile(medal: "🥉", name: "Lily Smith",
                             colors: [Color(hex: 0xF68FB7), Color(hex: 0xD93B6B)])
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(boardBg)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
    }

    private func boardProfile(medal: String, name: String,
                              colors: [Color]) -> some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    LinearGradient(colors: colors,
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                    Text(String(name.prefix(1)))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 54, height: 54)
                .clipShape(Circle())
                Text(medal)
                    .font(.system(size: 16))
                    .offset(x: 4, y: 4)
            }
            Text(name)
                .font(.system(size: 12))
                .foregroundStyle(textSecondary)
        }
    }

    // MARK: - CTA

    private var ctaButton: some View {
        Button {
            // Challenge creation arrives with the backend milestone.
        } label: {
            Text("Create New Challenges")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(hex: 0x8A8A8A))
                .clipShape(RoundedRectangle(cornerRadius: 26))
        }
    }

    // MARK: - Pills

    private func limePill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(lime, in: Capsule())
    }

    private func neutralPill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(hex: 0x3A3A3A), in: Capsule())
    }

    private func whitePill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.white, in: Capsule())
    }

    private func outlinePill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .overlay(Capsule().stroke(.black.opacity(0.4), lineWidth: 1))
    }
}
