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

struct MainTabView: View {
    var body: some View {
        TabView {
            CrossingsFeedView()
                .tabItem { Label("Crossings", systemImage: "arrow.triangle.swap") }
            RunTabView()
                .tabItem { Label("Run", systemImage: "figure.run") }
            MatchesView()
                .tabItem { Label("Matches", systemImage: "message.fill") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
    }
}
