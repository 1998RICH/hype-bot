import MapKit
import SwiftUI

/// One run: the route on a map (Strava-style), stats, and the runners you
/// crossed on this particular run — shown on the map where it happened.
struct RunDetailView: View {
    let runID: String
    @EnvironmentObject private var app: AppState
    @State private var detail: RunDetail?
    @State private var camera: MapCameraPosition = .automatic

    var body: some View {
        Group {
            if let detail {
                ScrollView {
                    VStack(spacing: 16) {
                        mapCard(detail)
                        statsCard(detail.summary)
                        crossedCard(detail)
                    }
                    .padding(16)
                }
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.cloud)
        .navigationTitle(detail?.summary.date.formatted(.dateTime.day().month().year()) ?? "Run")
        .navigationBarTitleDisplayMode(.inline)
        .task { detail = await app.runDetail(for: runID) }
    }

    private func mapCard(_ detail: RunDetail) -> some View {
        Map(position: $camera) {
            if detail.coordinates.count >= 2 {
                MapPolyline(coordinates: detail.coordinates)
                    .stroke(Theme.orange,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round,
                                               lineJoin: .round))
            }
            ForEach(detail.crossed) { runner in
                if let coordinate = runner.coordinate {
                    Annotation(runner.profile.firstName, coordinate: coordinate) {
                        AvatarView(profile: runner.profile, size: 32)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                            .shadow(color: .black.opacity(0.25), radius: 3)
                    }
                }
            }
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func statsCard(_ summary: RunSummary) -> some View {
        HStack {
            StatBlock(value: summary.distanceText, label: "Distance")
            StatBlock(value: summary.durationText, label: "Time")
            StatBlock(value: summary.paceText, label: "Pace")
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
    }

    private func crossedCard(_ detail: RunDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Crossed on this run")
                .font(.headline)
                .foregroundStyle(Theme.ink)
            if detail.crossed.isEmpty {
                Text("Nobody this time — the more you run, the more paths you cross. 🏃")
                    .font(.subheadline)
                    .foregroundStyle(Theme.slate)
            } else {
                ForEach(detail.crossed) { runner in
                    HStack(spacing: 12) {
                        AvatarView(profile: runner.profile, size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(runner.profile.firstName), \(runner.profile.age)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.ink)
                            Text("\(runner.overlapMinutes) min side by side")
                                .font(.caption)
                                .foregroundStyle(Theme.slate)
                        }
                        Spacer()
                    }
                }
                Text("Like or pass on them in the Crossings tab.")
                    .font(.caption)
                    .foregroundStyle(Theme.slate)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
    }
}
