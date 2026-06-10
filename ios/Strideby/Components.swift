import SwiftUI

struct AvatarView: View {
    let profile: RunnerProfile
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: profile.avatarColors,
                                     startPoint: .topLeading,
                                     endPoint: .bottomTrailing))
            Text(profile.emoji)
                .font(.system(size: size * 0.46))
        }
        .frame(width: size, height: size)
    }
}

struct TagPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.accent.opacity(0.13), in: Capsule())
            .overlay(Capsule().stroke(Theme.accent.opacity(0.25), lineWidth: 1))
            .foregroundStyle(Theme.accent)
    }
}

struct StatBlock: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.slate)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Reference-style chip: colored icon circle + bold value + small label.
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
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(Theme.slate)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassCard(radius: 18)
    }
}

/// Primary action button. Gradient in Neon Night, solid accent otherwise.
struct VoltButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.primaryFill, in: RoundedRectangle(cornerRadius: 18))
        }
        .shadow(color: Theme.accent.opacity(0.3), radius: 12, y: 4)
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
