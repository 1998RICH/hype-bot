import SwiftUI

/// Home — modeled on the reference: hero stat top-left, glass icon buttons,
/// neon hero panel with floating runner chips, stat chips, and a horizontal
/// rail of crossed-runner cards with neon borders.
struct CrossingsFeedView: View {
    @EnvironmentObject private var app: AppState
    @State private var selected: Crossing?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                topBar
                todayChip
                heroPanel
                chips
                crossedSection
                if let status = app.syncStatus {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(Theme.slate)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .background(Theme.bg.ignoresSafeArea())
        .sheet(item: $selected) { crossing in
            CrossingDetailSheet(crossing: crossing)
        }
    }

    private var totalKm: Double {
        app.runs.reduce(0) { $0 + $1.distanceMeters } / 1000
    }

    private var todayKm: Double {
        app.runs
            .filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.distanceMeters } / 1000
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: "%.1f", totalKm))
                    .font(.system(size: 46, weight: .black))
                    .fontWidth(.compressed)
                    .foregroundStyle(.white)
                Text("KM TOTAL RUNNING")
                    .font(.system(size: 10, weight: .heavy))
                    .kerning(1.6)
                    .foregroundStyle(Theme.slate)
            }
            Spacer()
            GlassIconButton(icon: "bell") {
                Task {
                    if app.isLive { await app.refresh() } else { app.syncDemoRun() }
                }
            }
            GlassIconButton(icon: "message") {
                app.requestedTab = .matches
            }
        }
    }

    private var todayChip: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: "figure.run")
                    .font(.caption.weight(.heavy))
                Text(String(format: "%.1f KM", todayKm))
                    .font(.system(size: 13, weight: .heavy))
                    .kerning(0.5)
            }
            .foregroundStyle(Theme.onAccent)
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(Theme.accent, in: Capsule())
            Text("Today's running")
                .font(.caption)
                .foregroundStyle(Theme.slate)
        }
    }

    /// Stand-in for the reference's hero illustration: ghost type, violet
    /// glow, and two glowing route lines crossing — with the runners you
    /// crossed floating over the spot.
    private var heroPanel: some View {
        ZStack {
            LinearGradient(colors: [Theme.cardElevated, Color(hex: 0x3A2A6B)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Text("RUN")
                .font(.system(size: 130, weight: .black))
                .fontWidth(.compressed)
                .italic()
                .foregroundStyle(.white.opacity(0.05))
                .offset(x: 10, y: 8)
            Circle()
                .fill(Theme.glow(Theme.violet, radius: 130))
                .frame(width: 280, height: 280)
                .offset(x: 70, y: -30)
            RoutePath()
                .stroke(Theme.accent,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .blur(radius: 6)
                .opacity(0.8)
                .padding(.horizontal, 24)
                .padding(.vertical, 30)
            RoutePath()
                .stroke(Theme.accent,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .padding(.horizontal, 24)
                .padding(.vertical, 30)
            RoutePath()
                .stroke(Theme.violet,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .scaleEffect(x: -1)
                .padding(.horizontal, 24)
                .padding(.vertical, 44)
            if app.pendingCrossings.indices.contains(0) {
                heroChip(app.pendingCrossings[0])
                    .offset(x: -86, y: -34)
            }
            if app.pendingCrossings.indices.contains(1) {
                heroChip(app.pendingCrossings[1])
                    .offset(x: 84, y: 38)
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(Theme.cardBorder, lineWidth: 1))
    }

    private func heroChip(_ crossing: Crossing) -> some View {
        HStack(spacing: 6) {
            AvatarView(profile: crossing.profile, size: 22)
            Text("\(crossing.closestDistanceMeters) m")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.black.opacity(0.45), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 1))
    }

    private var chips: some View {
        HStack(spacing: 8) {
            StatChip(icon: "flame.fill", iconColor: Theme.orange,
                     value: "\(app.runs.count)", label: "Runs")
            StatChip(icon: "bolt.fill", iconColor: Theme.accent,
                     value: "\(app.me.weeklyKm) km", label: "This week")
            StatChip(icon: "arrow.triangle.swap", iconColor: Theme.violet,
                     value: "\(app.pendingCrossings.count)", label: "New")
        }
    }

    private var crossedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Crossed Runners")
                    .font(.system(size: 22, weight: .black))
                    .fontWidth(.compressed)
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: 4) {
                    Text("View all")
                    Image(systemName: "arrow.right")
                }
                .font(.caption.weight(.heavy))
                .foregroundStyle(Theme.accent)
            }
            if app.pendingCrossings.isEmpty {
                emptyState
                    .frame(maxWidth: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(app.pendingCrossings.enumerated()),
                                id: \.element.id) { index, crossing in
                            CrossedRunnerCard(
                                crossing: crossing,
                                limeEdge: index.isMultiple(of: 2),
                                onLike: { app.like(crossing) },
                                onPass: { app.pass(crossing) }
                            )
                            .onTapGesture { selected = crossing }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.run")
                .font(.system(size: 40))
                .foregroundStyle(Theme.accent)
            Text("No new crossings")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Go for a run — anyone you cross shows up here after it syncs.")
                .font(.subheadline)
                .foregroundStyle(Theme.slate)
                .multilineTextAlignment(.center)
            if app.isLive {
                VoltButton(title: app.isSyncing ? "Syncing…" : "Sync runs") {
                    Task { await app.syncFromHealthKit() }
                }
                .disabled(app.isSyncing)
                .frame(width: 220)
            } else {
                VoltButton(title: "Simulate a run sync") { app.syncDemoRun() }
                    .frame(width: 240)
            }
        }
        .padding(.vertical, 24)
    }
}
