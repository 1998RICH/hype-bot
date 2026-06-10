import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var app: AppState
    @State private var ghostMode = false
    @State private var hideHomeZone = true

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                (Text("Your ").foregroundColor(.white)
                 + Text("profile").foregroundColor(Theme.accent))
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                headerCard
                designCard
                statsCard
                devicesCard
                privacyCard
                if app.isLive {
                    accountCard
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .background(Theme.bg.ignoresSafeArea())
    }

    private var headerCard: some View {
        card {
            HStack(spacing: 14) {
                AvatarView(profile: app.me, size: 84)
                    .overlay(Circle().stroke(Theme.accent.opacity(0.6), lineWidth: 2))
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(app.me.firstName), \(app.me.age)")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text(app.me.bio)
                        .font(.subheadline)
                        .foregroundStyle(Theme.slate)
                }
            }
            HStack(spacing: 8) {
                ForEach(app.me.tags, id: \.self) { tag in
                    TagPill(text: tag)
                }
            }
        }
    }

    private var designCard: some View {
        card {
            Text("Design lab")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Three directions, one app — pick the vibe.")
                .font(.caption)
                .foregroundStyle(Theme.slate)
            ForEach(DesignVariant.allCases) { variant in
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        app.design = variant
                    }
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(preview(variant))
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 1))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(variant.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text(variant.blurb)
                                .font(.caption)
                                .foregroundStyle(Theme.slate)
                        }
                        Spacer()
                        if app.design == variant {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    .padding(10)
                    .background(app.design == variant ? Theme.cardElevated : .clear,
                                in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private func preview(_ variant: DesignVariant) -> LinearGradient {
        switch variant {
        case .neonNight:
            return LinearGradient(colors: [Theme.orange, Theme.violet],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .voltMinimal:
            return LinearGradient(colors: [Theme.voltYellow, Theme.voltYellow],
                                  startPoint: .top, endPoint: .bottom)
        case .sunsetClub:
            return LinearGradient(colors: [Theme.amber, Theme.orange],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var statsCard: some View {
        card {
            Text("This week")
                .font(.headline)
                .foregroundStyle(.white)
            HStack {
                StatBlock(value: "\(app.me.weeklyKm) km", label: "Distance")
                StatBlock(value: app.me.pacePerKm, label: "Avg pace")
                StatBlock(value: "\(app.pendingCrossings.count)", label: "New crossings")
            }
        }
    }

    private var devicesCard: some View {
        card {
            Text("Connected devices")
                .font(.headline)
                .foregroundStyle(.white)
            Toggle(isOn: $app.appleWatchConnected) {
                Label("Apple Watch", systemImage: "applewatch")
                    .foregroundStyle(.white)
            }
            Toggle(isOn: $app.garminConnected) {
                Label("Garmin", systemImage: "antenna.radiowaves.left.and.right")
                    .foregroundStyle(.white)
            }
            if app.isLive {
                Button {
                    Task { await app.syncFromHealthKit() }
                } label: {
                    Label(app.isSyncing ? "Syncing…" : "Sync Apple Watch runs",
                          systemImage: "arrow.triangle.2.circlepath")
                        .foregroundStyle(Theme.accent)
                }
                .disabled(app.isSyncing)
                if let status = app.syncStatus {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(Theme.slate)
                }
                Text("Garmin sync is coming next (via Terra).")
                    .font(.caption)
                    .foregroundStyle(Theme.slate)
            } else {
                Text("Prototype note: device sync is simulated. Strideby can also record runs by itself — see the Run tab.")
                    .font(.caption)
                    .foregroundStyle(Theme.slate)
            }
        }
    }

    private var privacyCard: some View {
        card {
            Text("Privacy")
                .font(.headline)
                .foregroundStyle(.white)
            Toggle(isOn: $ghostMode) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ghost mode")
                        .foregroundStyle(.white)
                    Text("Keep running, stop appearing in other people's crossings.")
                        .font(.caption)
                        .foregroundStyle(Theme.slate)
                }
            }
            .onChange(of: ghostMode) { _, newValue in
                app.updatePrivacy(ghostMode: newValue)
            }
            Toggle(isOn: $hideHomeZone) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hide my home zone")
                        .foregroundStyle(.white)
                    Text("Crossings near your usual start and end points are never used.")
                        .font(.caption)
                        .foregroundStyle(Theme.slate)
                }
            }
            .onChange(of: hideHomeZone) { _, newValue in
                app.updatePrivacy(hideHomeZone: newValue)
            }
            Text("Your exact route and live location are never shown to other runners.")
                .font(.caption)
                .foregroundStyle(Theme.slate)
        }
    }

    private var accountCard: some View {
        card {
            Text("Account & testing")
                .font(.headline)
                .foregroundStyle(.white)
            Button {
                Task { await app.uploadTestRun() }
            } label: {
                Label("Upload a test run", systemImage: "wand.and.stars")
                    .foregroundStyle(Theme.accent)
            }
            Text("Two testers who both upload a test run will cross each other — handy for trying the full loop before you have real runs.")
                .font(.caption)
                .foregroundStyle(Theme.slate)
            Button(role: .destructive) {
                app.signOut()
            } label: {
                Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .glassCard(radius: 22)
            .tint(Theme.accent)
    }
}
