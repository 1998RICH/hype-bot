import SwiftUI

@main
struct StridebyApp: App {
    @StateObject private var app = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(app)
                .tint(Theme.volt)
                .preferredColorScheme(.dark)
        }
    }
}
