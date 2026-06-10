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
            .background(Theme.yellow.opacity(0.25), in: Capsule())
            .foregroundStyle(Theme.ink)
    }
}

struct StatBlock: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundStyle(Theme.ink)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.slate)
        }
        .frame(maxWidth: .infinity)
    }
}
