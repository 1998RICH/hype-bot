import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var app: AppState
    @State private var ghostMode = false
    @State private var hideHomeZone = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    statsCard
                    devicesCard
                    privacyCard
                }
                .padding(16)
            }
            .background(Theme.cloud)
            .navigationTitle("Profile")
        }
    }

    private var headerCard: some View {
        card {
            HStack(spacing: 14) {
                AvatarView(profile: app.me, size: 84)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(app.me.firstName), \(app.me.age)")
                        .font(.title3.bold())
                        .foregroundStyle(Theme.ink)
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

    private var statsCard: some View {
        card {
            Text("This week")
                .font(.headline)
                .foregroundStyle(Theme.ink)
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
                .foregroundStyle(Theme.ink)
            Toggle(isOn: $app.appleWatchConnected) {
                Label("Apple Watch", systemImage: "applewatch")
                    .foregroundStyle(Theme.ink)
            }
            Toggle(isOn: $app.garminConnected) {
                Label("Garmin", systemImage: "antenna.radiowaves.left.and.right")
                    .foregroundStyle(Theme.ink)
            }
            Text("Prototype note: device sync is simulated. The real app reads workouts from HealthKit and the Garmin Health API.")
                .font(.caption)
                .foregroundStyle(Theme.slate)
        }
    }

    private var privacyCard: some View {
        card {
            Text("Privacy")
                .font(.headline)
                .foregroundStyle(Theme.ink)
            Toggle(isOn: $ghostMode) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ghost mode")
                        .foregroundStyle(Theme.ink)
                    Text("Keep running, stop appearing in other people's crossings.")
                        .font(.caption)
                        .foregroundStyle(Theme.slate)
                }
            }
            Toggle(isOn: $hideHomeZone) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hide my home zone")
                        .foregroundStyle(Theme.ink)
                    Text("Crossings near your usual start and end points are never used.")
                        .font(.caption)
                        .foregroundStyle(Theme.slate)
                }
            }
            Text("Your exact route and live location are never shown to other runners.")
                .font(.caption)
                .foregroundStyle(Theme.slate)
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.white, in: RoundedRectangle(cornerRadius: 20))
    }
}
