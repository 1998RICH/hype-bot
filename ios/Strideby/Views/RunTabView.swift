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
            .background(Theme.bg.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { id in
                RunDetailView(runID: id)
            }
        }
        .task { await app.loadRuns() }
    }

    // MARK: - Idle: hero, week row, start, history

    private var idleView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                (Text("Let's ").foregroundColor(.white)
                 + Text("run").foregroundColor(Theme.accent))
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .padding(.top, 8)
                hero
                weekRow
                startCard
                if let status = app.syncStatus {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(Theme.slate)
                }
                if !app.runs.isEmpty {
                    runsList
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }

    private var weeklyKm: Double {
        let cutoff = Date.now.addingTimeInterval(-7 * 86_400)
        return app.runs
            .filter { $0.date > cutoff }
            .reduce(0) { $0 + $1.distanceMeters } / 1000
    }

    private var hero: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(String(format: "%.1f", weeklyKm))
                .font(.system(size: 56, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
            Text("km this week")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.slate)
        }
    }

    /// Last 7 days; days you ran get an accent check (reference-style).
    private var weekRow: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { offset in
                let day = Calendar.current.date(byAdding: .day,
                                                value: offset - 6,
                                                to: .now) ?? .now
                let ran = app.runs.contains {
                    Calendar.current.isDate($0.date, inSameDayAs: day)
                }
                VStack(spacing: 6) {
                    Text(day.formatted(.dateTime.weekday(.narrow)))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.slate)
                    ZStack {
                        Circle()
                            .fill(ran ? AnyShapeStyle(Theme.accent)
                                      : AnyShapeStyle(Theme.card))
                        if ran {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(Theme.onAccent)
                        }
                    }
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Theme.cardBorder, lineWidth: ran ? 0 : 1))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(12)
        .glassCard(radius: 20)
    }

    private var startCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.run")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(startForeground)
            Text("Ready to cross paths?")
                .font(.title3.bold())
                .foregroundStyle(startForeground)
            Text("Strideby records your route while you run — your phone in a pocket is all you need.")
                .font(.subheadline)
                .foregroundStyle(startForeground.opacity(0.75))
                .multilineTextAlignment(.center)
            Button {
                recorder.start()
            } label: {
                Text("Start running")
                    .font(.headline)
                    .foregroundStyle(startButtonForeground)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(startButtonBackground, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(startBackground, in: RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26)
            .stroke(Theme.variant == .voltMinimal ? Theme.cardBorder : .clear, lineWidth: 1))
    }

    // Start card flavor per design direction: gradient hero (Neon Night),
    // quiet card (Volt Minimal), or a bold accent block (Sunset Club).
    private var startBackground: AnyShapeStyle {
        switch Theme.variant {
        case .neonNight: return Theme.primaryFill
        case .voltMinimal: return AnyShapeStyle(Theme.card)
        case .sunsetClub: return AnyShapeStyle(Theme.accent)
        }
    }

    private var startForeground: Color {
        switch Theme.variant {
        case .neonNight: return .white
        case .voltMinimal: return .white
        case .sunsetClub: return Theme.onAccent
        }
    }

    private var startButtonBackground: AnyShapeStyle {
        switch Theme.variant {
        case .neonNight: return AnyShapeStyle(Color.white)
        case .voltMinimal: return AnyShapeStyle(Theme.accent)
        case .sunsetClub: return AnyShapeStyle(Theme.bg)
        }
    }

    private var startButtonForeground: Color {
        switch Theme.variant {
        case .neonNight: return Theme.orange
        case .voltMinimal: return Theme.onAccent
        case .sunsetClub: return .white
        }
    }

    private var runsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("My runs")
                .font(.headline)
                .foregroundStyle(.white)
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
                .foregroundStyle(Theme.accent)
                .frame(width: 40, height: 40)
                .background(Theme.accent.opacity(0.13), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                Text(run.date.formatted(.dateTime.weekday(.wide).day().month()))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text("\(run.distanceText) · \(run.durationText) · \(run.paceText)")
                    .font(.caption)
                    .foregroundStyle(Theme.slate)
            }
            Spacer()
            if run.crossingCount > 0 {
                Text("\(run.crossingCount) crossed")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.accent, in: Capsule())
                    .foregroundStyle(Theme.onAccent)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.slate)
        }
        .padding(12)
        .glassCard(radius: 18)
    }

    // MARK: - Recording

    private var recordingView: some View {
        ZStack {
            Circle()
                .fill(Theme.glow(Theme.orange, radius: 260))
                .frame(width: 600, height: 600)
            VStack(spacing: 28) {
                Spacer()
                HStack(spacing: 8) {
                    Circle().fill(Theme.accent).frame(width: 8, height: 8)
                    Text("RECORDING")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(Theme.accent)
                        .kerning(2)
                }
                Text(timeString(recorder.elapsed))
                    .font(.system(size: 68, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                HStack {
                    StatBlock(value: String(format: "%.2f km", recorder.distanceMeters / 1000),
                              label: "Distance")
                    StatBlock(value: livePace, label: "Pace")
                }
                .padding(16)
                .glassCard(radius: 20)
                Spacer()
                VoltButton(title: "Finish run") {
                    let points = recorder.stop()
                    Task { await app.finishRun(points: points) }
                }
                .padding(.bottom, 16)
            }
            .padding(24)
        }
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
