import SwiftUI

struct RootView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        Group {
            if app.hasOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .overlay {
            if let match = app.newMatch {
                MatchOverlayView(match: match)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: app.newMatch?.id)
        .fullScreenCover(isPresented: $app.needsAuth) {
            AuthView()
                .interactiveDismissDisabled()
        }
    }
}

enum MainTab {
    case crossings, run, challenges, matches, profile

    var icon: String {
        switch self {
        case .crossings: return "house.fill"
        case .run: return "figure.run"
        case .challenges: return "trophy.fill"
        case .matches: return "message.fill"
        case .profile: return "person.fill"
        }
    }

    var title: String {
        switch self {
        case .crossings: return "Home"
        case .run: return "Run"
        case .challenges: return "Challenges"
        case .matches: return "Matches"
        case .profile: return "Profile"
        }
    }
}

/// Custom floating pill tab bar + a circular "go run" button, in the style
/// of the reference designs.
struct MainTabView: View {
    @EnvironmentObject private var app: AppState
    @State private var tab: MainTab = .crossings

    private let barTabs: [MainTab] = [.crossings, .challenges, .matches, .profile]

    var body: some View {
        ZStack(alignment: .bottom) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: app.hideTabBar ? 0 : 78)
                }
            if !app.hideTabBar {
                bar
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .onChange(of: app.requestedTab) { _, newValue in
            if let newValue {
                withAnimation(.snappy) { tab = newValue }
                app.requestedTab = nil
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .crossings: CrossingsFeedView()
        case .run: RunTabView()
        case .challenges: ChallengesView()
        case .matches: MatchesView()
        case .profile: ProfileView()
        }
    }

    private var bar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 2) {
                ForEach(barTabs, id: \.icon) { item in
                    tabButton(item)
                }
            }
            .padding(6)
            .background(Theme.cardElevated, in: Capsule())
            .overlay(Capsule().stroke(Theme.cardBorder, lineWidth: 1))

            Button {
                withAnimation(.snappy) { tab = .run }
            } label: {
                ZStack {
                    Circle()
                        .fill(tab == .run
                              ? AnyShapeStyle(Theme.accent)
                              : AnyShapeStyle(Theme.purpleGradient))
                        .frame(width: 58, height: 58)
                    Image(systemName: "figure.run")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(tab == .run ? Theme.onAccent : .white)
                }
            }
            .shadow(color: (tab == .run ? Theme.accent : Theme.violet).opacity(0.45),
                    radius: 14, y: 4)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }

    private func tabButton(_ item: MainTab) -> some View {
        Button {
            withAnimation(.snappy) { tab = item }
        } label: {
            if tab == item {
                HStack(spacing: 6) {
                    Image(systemName: item.icon)
                        .font(.subheadline.weight(.semibold))
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(Theme.onVolt)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Theme.volt, in: Capsule())
            } else {
                Image(systemName: item.icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.slate)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
            }
        }
    }
}
