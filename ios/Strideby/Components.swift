import SwiftUI

// MARK: - Brand graphics

/// A winding route line — Strideby's brand motif. Drawn, not an icon.
struct RoutePath: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY * 0.9))
        p.addCurve(to: CGPoint(x: rect.midX, y: rect.midY),
                   control1: CGPoint(x: rect.width * 0.25, y: rect.maxY * 1.05),
                   control2: CGPoint(x: rect.width * 0.35, y: rect.minY))
        p.addCurve(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.15),
                   control1: CGPoint(x: rect.width * 0.7, y: rect.maxY),
                   control2: CGPoint(x: rect.width * 0.85, y: rect.minY))
        return p
    }
}

/// Repeating brand strip, streetwear-style.
struct TickerStrip: View {
    var phrase = "STRIDEBY • CROSS PATHS • MATCH STRIDES • "

    var body: some View {
        Text(String(repeating: phrase, count: 6))
            .font(.system(size: 12, weight: .heavy))
            .kerning(2)
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(Theme.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Theme.accent)
            .clipped()
    }
}

/// Eyebrow + huge compressed display title, the screen-header signature.
struct ScreenHeader: View {
    let eyebrow: String
    let leading: String
    let accent: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.heavy))
                .kerning(2.5)
                .foregroundStyle(Theme.slate)
            (Text(leading + " ").foregroundColor(.white)
             + Text(accent).foregroundColor(Theme.accent))
                .font(.system(size: 42, weight: .black))
                .fontWidth(.compressed)
                .italic()
        }
    }
}

// MARK: - People

/// Monogram avatar: a designed initial over a duotone gradient with the
/// route motif ghosted behind. (Real photos arrive with the photo-upload
/// milestone; this is the placeholder identity system.)
struct AvatarView: View {
    let profile: RunnerProfile
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            LinearGradient(colors: profile.avatarColors,
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
            RoutePath()
                .stroke(.white.opacity(0.28),
                        style: StrokeStyle(lineWidth: max(1.5, size * 0.04),
                                           lineCap: .round))
                .frame(width: size * 0.72, height: size * 0.5)
            Text(String(profile.firstName.prefix(1)).uppercased())
                .font(.system(size: size * 0.46, weight: .black))
                .fontWidth(.compressed)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - Chips & blocks

struct TagPill: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .heavy))
            .kerning(0.8)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(Theme.accent.opacity(0.13), in: Capsule())
            .overlay(Capsule().stroke(Theme.accent.opacity(0.3), lineWidth: 1))
            .foregroundStyle(Theme.accent)
    }
}

struct StatBlock: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .black))
                .fontWidth(.compressed)
                .foregroundStyle(.white)
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .kerning(1)
                .foregroundStyle(Theme.slate)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Colored icon circle + bold value + small label.
struct StatChip: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(iconColor.opacity(0.18))
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(iconColor)
            }
            .frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 15, weight: .black))
                    .fontWidth(.compressed)
                    .foregroundStyle(.white)
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .kerning(0.8)
                    .foregroundStyle(Theme.slate)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassCard(radius: 18)
    }
}

/// Primary action button — loud, condensed, unmistakable.
struct VoltButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(.system(size: 16, weight: .heavy))
                .kerning(1.4)
                .foregroundStyle(Theme.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(Theme.primaryFill, in: RoundedRectangle(cornerRadius: 18))
        }
        .shadow(color: Theme.accent.opacity(0.3), radius: 12, y: 4)
    }
}

/// Small round glassy icon button (header bell / chat, reference-style).
struct GlassIconButton: View {
    let icon: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Theme.card, in: Circle())
                .overlay(Circle().stroke(Theme.cardBorder, lineWidth: 1))
        }
    }
}

/// Lime line chart with gradient fill and dots — the reference's stats card.
struct WeeklyChart: View {
    let values: [Double]

    var body: some View {
        GeometryReader { geo in
            let maxValue = max(values.max() ?? 1, 0.1)
            let count = max(values.count - 1, 1)
            let points = values.enumerated().map { index, value in
                CGPoint(x: geo.size.width * CGFloat(index) / CGFloat(count),
                        y: geo.size.height * (1 - 0.85 * CGFloat(value / maxValue)) - 3)
            }
            ZStack {
                Path { path in
                    guard let first = points.first, let last = points.last else { return }
                    path.move(to: CGPoint(x: first.x, y: geo.size.height))
                    points.forEach { path.addLine(to: $0) }
                    path.addLine(to: CGPoint(x: last.x, y: geo.size.height))
                    path.closeSubpath()
                }
                .fill(LinearGradient(colors: [Theme.accent.opacity(0.32), .clear],
                                     startPoint: .top, endPoint: .bottom))
                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    points.dropFirst().forEach { path.addLine(to: $0) }
                }
                .stroke(Theme.accent,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round,
                                           lineJoin: .round))
                ForEach(points.indices, id: \.self) { index in
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 5, height: 5)
                        .position(points[index])
                }
            }
        }
    }
}

private struct GlassCardModifier: ViewModifier {
    var radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(Theme.card, in: RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(Theme.cardBorder, lineWidth: 1)
            )
    }
}

extension View {
    /// Dark glassy card surface with a thin light border.
    func glassCard(radius: CGFloat = 24) -> some View {
        modifier(GlassCardModifier(radius: radius))
    }
}
