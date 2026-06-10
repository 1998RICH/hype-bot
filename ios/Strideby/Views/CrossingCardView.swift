import SwiftUI

struct CrossingCardView: View {
    let crossing: Crossing
    /// Horizontal drag of the top card; drives the LIKE/PASS stamps.
    var dragX: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            header
            details
            Spacer(minLength: 0)
        }
        .frame(height: 470)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Theme.heroBorder, lineWidth: 1.5))
        .shadow(color: .black.opacity(0.5), radius: 18, y: 10)
        .overlay(alignment: .topLeading) {
            stamp("LIKE", color: Theme.accent, rotation: -12, visible: dragX > 40)
        }
        .overlay(alignment: .topTrailing) {
            stamp("PASS", color: .red, rotation: 12, visible: dragX < -40)
        }
    }

    private var header: some View {
        ZStack {
            LinearGradient(colors: crossing.profile.avatarColors,
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
            Text(crossing.profile.emoji)
                .font(.system(size: 92))
            LinearGradient(colors: [.clear, .black.opacity(0.55)],
                           startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading) {
                crossingBanner
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(crossing.profile.firstName), \(crossing.profile.age)")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    Text(crossing.profile.favoriteDistance)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.16), in: Capsule())
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
        }
        .frame(height: 240)
    }

    private var crossingBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.triangle.swap")
            Text("\(crossing.routeName) · \(crossing.date.formatted(.dateTime.weekday(.abbreviated).hour().minute()))")
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(Theme.onAccent)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.accent, in: Capsule())
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                StatBlock(value: crossing.theirPace, label: "Their pace")
                StatBlock(value: "\(crossing.overlapMinutes) min", label: "Side by side")
                StatBlock(value: "\(crossing.closestDistanceMeters) m", label: "Closest pass")
            }
            Text(crossing.profile.bio)
                .font(.subheadline)
                .foregroundStyle(Theme.slate)
                .lineLimit(3)
            HStack(spacing: 8) {
                ForEach(crossing.profile.tags, id: \.self) { tag in
                    TagPill(text: tag)
                }
            }
        }
        .padding(16)
    }

    private func stamp(_ text: String, color: Color, rotation: Double,
                       visible: Bool) -> some View {
        Text(text)
            .font(.title3.weight(.heavy))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(color, lineWidth: 3))
            .rotationEffect(.degrees(rotation))
            .opacity(visible ? 1 : 0)
            .padding(20)
    }
}
