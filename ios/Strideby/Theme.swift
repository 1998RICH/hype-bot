import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Strideby design language: "Strava and Bumble had a baby."
/// Strava's bold orange drives action and energy; Bumble's warm yellow
/// softens it for the social/dating side.
enum Theme {
    /// Primary brand + action color (Strava-inspired).
    static let orange = Color(hex: 0xFC5200)
    /// Accent color (Bumble-inspired).
    static let yellow = Color(hex: 0xFFC629)
    /// Midpoint used in gradients.
    static let amber = Color(hex: 0xFF8A00)

    static let ink = Color(hex: 0x231F1A)
    static let slate = Color(hex: 0x6F6A62)
    /// Warm off-white app background.
    static let cloud = Color(hex: 0xFAF6F0)

    static let brandGradient = LinearGradient(
        colors: [orange, amber, yellow],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let sunriseGradient = LinearGradient(
        colors: [yellow, orange],
        startPoint: .top,
        endPoint: .bottom
    )
}
