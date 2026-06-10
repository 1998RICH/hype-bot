import SwiftUI

/// Record a run with the phone's GPS and browse past runs.
struct RunTabView: View {
    @EnvironmentObject private var app: AppState
    @StateObject private var recorder = RunRecorder()

    var body: some View {
        NavigationStack {
            Group {
                if recorder.isRecording {
                    recordingView
                } else {
                    idleView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.cloud)
            .navigationTitle("Run")
            .navigationDestination(for: String.self) { id in
                RunDetailView(runID: id)
            }
        }
        .task { await app.loadRuns() }
    }

    // MARK: - Idle: start button + run history

    private var idleView: some View {
        ScrollView {
            VStack(spacing: 16) {
                startCard
                if let status = app.syncStatus {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(Theme.slate)
                        .multilineTextAlignment(.center)
                }
                if !app.runs.isEmpty {
                    runsList
                }
            }
            .padding(16)
        }
    }

    private var startCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.run")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white)
            Text("Ready to cross paths?")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text("Strideby records your route while you run — your phone in a pocket is all you need.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
            Button {
                recorder.start()
            } label: {
                Text("Start running")
                    .font(.headline)
                    .foregroundStyle(Theme.orange)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(.white, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(20)
        .background(Theme.brandGradient, in: RoundedRectangle(cornerRadius: 24))
    }

    private var runsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("My runs")
                .font(.headline)
                .foregroundStyle(Theme.ink)
            ForEach(app.runs) { run in
                NavigationLink(value: run.id) {
                    runRow(run)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func runRow(_ run: RunSummary) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "map")
                .foregroundStyle(Theme.orange)
                .frame(width: 40, height: 40)
                .background(Theme.yellow.opacity(0.25), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(run.date.formatted(.dateTime.weekday(.wide).day().month()))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Text("\(run.distanceText) · \(run.durationText) · \(run.paceText)")
                    .font(.caption)
                    .foregroundStyle(Theme.slate)
            }
            Spacer()
            if run.crossingCount > 0 {
                Text("\(run.crossingCount) crossed")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.yellow.opacity(0.3), in: Capsule())
                    .foregroundStyle(Theme.ink)
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.slate)
        }
        .padding(12)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Recording

    private var recordingView: some View {
        VStack(spacing: 28) {
            Spacer()
            Label("Recording", systemImage: "dot.radiowaves.left.and.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.orange)
            Text(timeString(recorder.elapsed))
                .font(.system(size: 64, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(Theme.ink)
            HStack {
                StatBlock(value: String(format: "%.2f km", recorder.distanceMeters / 1000),
                          label: "Distance")
                StatBlock(value: livePace, label: "Pace")
            }
            .padding(16)
            .background(.white, in: RoundedRectangle(cornerRadius: 20))
            Spacer()
            Button {
                let points = recorder.stop()
                Task { await app.finishRun(points: points) }
            } label: {
                Text("Finish run")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(Theme.brandGradient, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.bottom, 16)
        }
        .padding(24)
    }

    private var livePace: String {
        guard recorder.distanceMeters > 50 else { return "–" }
        let secondsPerKm = recorder.elapsed / (recorder.distanceMeters / 1000)
        return String(format: "%d:%02d /km", Int(secondsPerKm) / 60, Int(secondsPerKm) % 60)
    }

    private func timeString(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        if total >= 3600 {
            return String(format: "%d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
        }
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
