import Foundation

enum AppConfig {
    /// Demo mode vs live mode switch.
    ///
    /// Leave nil and the app runs fully on mock data (no server needed) —
    /// perfect for showing people the experience.
    ///
    /// Deploy the backend (see server/README.md), then set this to its URL
    /// and the app switches to real accounts, HealthKit run sync, and real
    /// crossings:
    ///     static let apiBaseURL: URL? = URL(string: "https://your-app.onrender.com")
    static let apiBaseURL: URL? = nil
}
