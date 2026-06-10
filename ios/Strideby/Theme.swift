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

/// Three original design directions, each loosely inspired by one of the
/// founder's reference shots — interpreted, not copied, and all carrying
/// Strideby's warm orange/yellow identity. Switch live from
/// Profile → Design lab.
enum DesignVariant: String, CaseIterable, Identifiable {
    /// Plum darkness, gradient fills, violet haze, neon card edges.
    case neonNight
    /// Neutral near-black, flat clean cards, electric yellow accent.
    case voltMinimal
    /// Pure black, chunky shapes, bold amber accent blocks.
    case sunsetClub

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .neonNight: return "Neon Night"
        case .voltMinimal: return "Volt Minimal"
        case .sunsetClub: return "Sunset Club"
        }
    }

    var blurb: String {
        switch self {
        case .neonNight: return "Glowing gradients & violet haze"
        case .voltMinimal: return "Clean black & electric yellow"
        case .sunsetClub: return "Bold blocks & burnt amber"
        }
    }
}

enum Theme {
    /// Kept in sync by AppState; views re-read it on every render.
    static var variant: DesignVariant = .voltMinimal

    // Brand hues (shared by all variants)
    static let orange = Color(hex: 0xFF5A1F)
    static let amber = Color(hex: 0xFFA51F)
    static let voltYellow = Color(hex: 0xFFD234)
    static let violet = Color(hex: 0x8B5CF6)

    // MARK: Surfaces

    static var bg: Color {
        switch variant {
        case .neonNight: return Color(hex: 0x141021)
        case .voltMinimal: return Color(hex: 0x0D0D10)
        case .sunsetClub: return Color(hex: 0x0A0A0A)
        }
    }

    static var card: Color {
        switch variant {
        case .neonNight: return Color(hex: 0x211A35)
        case .voltMinimal: return Color(hex: 0x1A1A20)
        case .sunsetClub: return Color(hex: 0x171614)
        }
    }

    static var cardElevated: Color {
        switch variant {
        case .neonNight: return Color(hex: 0x2D2349)
        case .voltMinimal: return Color(hex: 0x24242C)
        case .sunsetClub: return Color(hex: 0x21201D)
        }
    }

    static var cardBorder: Color {
        Color.white.opacity(variant == .neonNight ? 0.10 : 0.07)
    }

    // MARK: Accent system

    /// Volt lime — the loud CTA color of the reference model.
    static let lime = Color(hex: 0xC8F549)

    static var accent: Color {
        switch variant {
        case .neonNight: return lime
        case .voltMinimal: return voltYellow
        case .sunsetClub: return amber
        }
    }

    static var onAccent: Color {
        switch variant {
        case .neonNight: return Color(hex: 0x1B2404)
        case .voltMinimal: return Color(hex: 0x201602)
        case .sunsetClub: return Color(hex: 0x211200)
        }
    }

    /// Secondary actions & the floating run button (reference: purple).
    static var purpleGradient: LinearGradient {
        LinearGradient(colors: [Color(hex: 0x9D6BFF), Color(hex: 0x6D28D9)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var primaryFill: AnyShapeStyle {
        AnyShapeStyle(accent)
    }

    /// Neon edge for hero cards — lime fading into purple, like the model.
    static var heroBorder: AnyShapeStyle {
        switch variant {
        case .neonNight:
            return AnyShapeStyle(LinearGradient(
                colors: [lime.opacity(0.95), lime.opacity(0.2), violet.opacity(0.95)],
                startPoint: .top, endPoint: .bottom))
        case .voltMinimal, .sunsetClub:
            return AnyShapeStyle(cardBorder)
        }
    }

    static var glowOpacity: Double {
        switch variant {
        case .neonNight: return 0.38
        case .voltMinimal: return 0.10
        case .sunsetClub: return 0.22
        }
    }

    // MARK: Text

    static let ink = Color.white

    static var slate: Color {
        switch variant {
        case .neonNight: return Color(hex: 0xB7AECE)
        case .voltMinimal: return Color(hex: 0xA3A3AE)
        case .sunsetClub: return Color(hex: 0xA9A29A)
        }
    }

    // MARK: Aliases & shared styles

    static var volt: Color { accent }
    static var onVolt: Color { onAccent }
    static var yellow: Color { voltYellow }
    static var cloud: Color { bg }

    static var brandGradient: LinearGradient {
        LinearGradient(colors: [orange, amber, voltYellow],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var sunriseGradient: LinearGradient {
        LinearGradient(colors: [voltYellow, orange],
                       startPoint: .top, endPoint: .bottom)
    }

    /// Ambient glow behind hero elements; strength varies by variant.
    static func glow(_ color: Color, radius: CGFloat = 220) -> RadialGradient {
        RadialGradient(colors: [color.opacity(glowOpacity), .clear],
                       center: .center, startRadius: 8, endRadius: radius)
    }
}
