import SwiftUI

/// Stats + recording — modeled on the reference's second screen: greeting,
/// "running journey" card with progress and dual pills, matches row, and a
/// lime line chart with day pills.
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

    // MARK: - Idle

    private var idleView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                greeting
                journeyCard
                if !app.matches.isEmpty {
                    matchesRow
                }
                chartCard
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
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Hello \(app.me.firstName)!")
                .font(.system(size: 34, weight: .black))
                .fontWidth(.compressed)
                .foregroundStyle(.white)
            (Text("Find your ").foregroundColor(Theme.slate)
             + Text("crossings").foregroundColor(Theme.accent)
             + Text(" here.").foregroundColor(Theme.slate))
                .font(.subheadline)
        }
    }

    private var todayKm: Double {
        app.runs
            .filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.distanceMeters } / 1000
    }

    private var journeyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Today's running journey")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Track goals. Cross paths. Keep moving.")
                        .font(.caption)
                        .foregroundStyle(Theme.slate)
                }
                Spacer()
                VStack(spacing: 1) {
                    Text(String(format: "%.1f", todayKm))
                        .font(.system(size: 21, weight: .black))
                        .fontWidth(.compressed)
                        .foregroundStyle(.white)
                    Text("KM")
                        .font(.system(size: 9, weight: .heavy))
                        .kerning(1)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(width: 60, height: 54)
                .background(Theme.purpleGradient, in: RoundedRectangle(cornerRadius: 16))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.10))
                    Capsule()
                        .fill(Theme.accent)
                        .frame(width: geo.size.width * min(todayKm / 5.0, 1))
                }
            }
            .frame(height: 6)
            HStack(spacing: 10) {
                Button {
                    recorder.start()
                } label: {
                    Text("START RUNNING")
                        .font(.system(size: 12, weight: .heavy))
                        .kerning(1)
                        .foregroundStyle(Theme.onAccent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(Theme.accent, in: Capsule())
                }
                Button {
                    Task {
                        if app.isLive { await app.uploadTestRun() }
                        else { app.syncDemoRun() }
                    }
                } label: {
                    Text(app.isLive ? "TEST RUN" : "DEMO SYNC")
                        .font(.system(size: 12, weight: .heavy))
                        .kerning(1)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(Theme.purpleGradient, in: Capsule())
                }
            }
        }
        .padding(16)
        .glassCard(radius: 24)
    }

    private var matchesRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YOUR MATCHES")
                .font(.system(size: 11, weight: .heavy))
                .kerning(1.6)
                .foregroundStyle(Theme.slate)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(app.matches) { match in
                        Button {
                            app.requestedTab = .matches
                        } label: {
                            VStack(spacing: 5) {
                                AvatarView(profile: match.crossing.profile, size: 58)
                                    .overlay(Circle().stroke(Theme.purpleGradient, lineWidth: 2))
                                Text(match.crossing.profile.firstName)
                                    .font(.caption)
                                    .foregroundStyle(Theme.slate)
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Chart

    private var dailyKm: [Double] {
        (0..<7).map { offset in
            let day = Calendar.current.date(byAdding: .day, value: offset - 6,
                                            to: .now) ?? .now
            return app.runs
                .filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.distanceMeters } / 1000
        }
    }

    private var weekDeltaPercent: Int? {
        let cutoff = Date.now.addingTimeInterval(-7 * 86_400)
        let previousCutoff = Date.now.addingTimeInterval(-14 * 86_400)
        let thisWeek = app.runs.filter { $0.date > cutoff }
            .reduce(0) { $0 + $1.distanceMeters }
        let lastWeek = app.runs.filter { $0.date > previousCutoff && $0.date <= cutoff }
            .reduce(0) { $0 + $1.distanceMeters }
        guard lastWeek > 100 else { return nil }
        return Int(((thisWeek - lastWeek) / lastWeek) * 100)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Last 7 days")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if let delta = weekDeltaPercent {
                    HStack(spacing: 4) {
                        Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text("\(abs(delta))%")
                    }
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(delta >= 0 ? Theme.accent : .red)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.07), in: Capsule())
                }
            }
            WeeklyChart(values: dailyKm)
                .frame(height: 100)
            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { offset in
                    let day = Calendar.current.date(byAdding: .day,
                                                    value: offset - 6,
                                                    to: .now) ?? .now
                    Text(day.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.slate)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.05), in: Capsule())
                }
            }
        }
        .padding(16)
        .glassCard(radius: 24)
    }

    private var runsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("My runs")
                .font(.system(size: 22, weight: .black))
                .fontWidth(.compressed)
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
                Text("\(run.crossingCount) CROSSED")
                    .font(.system(size: 10, weight: .heavy))
                    .kerning(0.6)
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
                .fill(Theme.glow(Theme.violet, radius: 260))
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
                    .font(.system(size: 76, weight: .black).monospacedDigit())
                    .fontWidth(.compressed)
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
