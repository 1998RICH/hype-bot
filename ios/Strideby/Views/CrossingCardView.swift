import MapKit
import SwiftUI

/// Reference-style runner card for the home rail: neon-edged glass card,
/// name + badge, distance of the pass, avatar, and a white pill action.
struct CrossedRunnerCard: View {
    let crossing: Crossing
    /// Cards alternate lime / purple edges, like the model.
    var limeEdge = true
    var onLike: () -> Void
    var onPass: () -> Void

    private var edge: LinearGradient {
        LinearGradient(
            colors: limeEdge
                ? [Theme.accent.opacity(0.95), Theme.accent.opacity(0.15), Theme.violet.opacity(0.6)]
                : [Theme.violet.opacity(0.95), Theme.violet.opacity(0.15), Theme.accent.opacity(0.6)],
            startPoint: .top, endPoint: .bottom)
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(crossing.profile.firstName)")
                    .font(.system(size: 19, weight: .black))
                    .fontWidth(.compressed)
                    .foregroundStyle(.white)
                Spacer()
                Button(action: onPass) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(Theme.slate)
                        .frame(width: 24, height: 24)
                        .background(.white.opacity(0.08), in: Circle())
                }
            }
            HStack(spacing: 5) {
                Image(systemName: "figure.run")
                    .font(.system(size: 9, weight: .heavy))
                Text("\(crossing.profile.favoriteDistance.uppercased()) RUNNER")
                    .font(.system(size: 9, weight: .heavy))
                    .kerning(0.6)
            }
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Theme.accent.opacity(0.13), in: Capsule())
            Text("crossed \(crossing.closestDistanceMeters) m apart")
                .font(.caption2)
                .foregroundStyle(Theme.slate)
            AvatarView(profile: crossing.profile, size: 78)
                .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 2))
                .padding(.vertical, 2)
            Button(action: onLike) {
                Text("LIKE")
                    .font(.system(size: 12, weight: .heavy))
                    .kerning(1.2)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(.white, in: Capsule())
            }
        }
        .padding(13)
        .frame(width: 172)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(edge, lineWidth: 1.5))
        .shadow(color: (limeEdge ? Theme.accent : Theme.violet).opacity(0.18),
                radius: 12, y: 6)
    }
}

/// Tapping a card opens the full story: a dark map of where you crossed,
/// stats, bio, and like/pass.
struct CrossingDetailSheet: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    let crossing: Crossing

    var body: some View {
        VStack(spacing: 16) {
            mapHero
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    StatBlock(value: crossing.theirPace, label: "Their pace")
                    StatBlock(value: "\(crossing.overlapMinutes) min", label: "Side by side")
                    StatBlock(value: "\(crossing.closestDistanceMeters) m", label: "Closest pass")
                }
                Text(crossing.profile.bio)
                    .font(.subheadline)
                    .foregroundStyle(Theme.slate)
                HStack(spacing: 8) {
                    ForEach(crossing.profile.tags, id: \.self) { tag in
                        TagPill(text: tag)
                    }
                }
            }
            .padding(16)
            .glassCard(radius: 22)
            HStack(spacing: 40) {
                Button {
                    app.pass(crossing)
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.slate)
                        .frame(width: 60, height: 60)
                        .background(Theme.card, in: Circle())
                        .overlay(Circle().stroke(Theme.cardBorder, lineWidth: 1))
                }
                Button {
                    app.like(crossing)
                    dismiss()
                } label: {
                    Image(systemName: "heart.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.onAccent)
                        .frame(width: 60, height: 60)
                        .background(Theme.accent, in: Circle())
                        .shadow(color: Theme.accent.opacity(0.4), radius: 12, y: 4)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.ignoresSafeArea())
        .presentationBackground(Theme.bg)
        .presentationDragIndicator(.visible)
    }

    private var mapHero: some View {
        ZStack {
            if let coordinate = crossing.coordinate {
                Map(initialPosition: .region(MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.012,
                                               longitudeDelta: 0.012))),
                    interactionModes: []) {
                    Annotation("", coordinate: coordinate) {
                        ZStack {
                            Circle().fill(Theme.accent.opacity(0.22))
                                .frame(width: 52, height: 52)
                            Circle().fill(Theme.accent.opacity(0.4))
                                .frame(width: 28, height: 28)
                            Circle().fill(Theme.accent)
                                .frame(width: 13, height: 13)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                        }
                    }
                }
                .mapStyle(.standard(pointsOfInterest: .excludingAll))
            } else {
                LinearGradient(colors: crossing.profile.avatarColors,
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
            }
            LinearGradient(colors: [.black.opacity(0.3), .clear, .black.opacity(0.72)],
                           startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.swap")
                    Text("\(crossing.routeName) · \(crossing.date.formatted(.dateTime.weekday(.abbreviated).hour().minute()))".uppercased())
                        .kerning(0.6)
                }
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(Theme.onAccent)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.accent, in: Capsule())
                Spacer()
                HStack(spacing: 10) {
                    AvatarView(profile: crossing.profile, size: 52)
                        .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 2))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(crossing.profile.firstName), \(crossing.profile.age)")
                            .font(.system(size: 30, weight: .black))
                            .fontWidth(.compressed)
                            .foregroundStyle(.white)
                        Text(crossing.profile.favoriteDistance.uppercased() + " RUNNER")
                            .font(.system(size: 10, weight: .heavy))
                            .kerning(1.2)
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
        }
        .frame(height: 260)
        .allowsHitTesting(false)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(Theme.heroBorder, lineWidth: 1.5))
    }
}
