import SwiftUI

/// Home: greeting, stat chips, and the swipe deck of runners you crossed.
struct CrossingsFeedView: View {
    @EnvironmentObject private var app: AppState
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            chips
            if app.pendingCrossings.isEmpty {
                Spacer()
                emptyState
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                cardStack
                    .frame(maxHeight: .infinity)
                actionButtons
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.bg.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Hey \(app.me.firstName) 👋")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.slate)
            (Text("Runners you ").foregroundColor(.white)
             + Text("crossed").foregroundColor(Theme.accent))
                .font(.system(size: 30, weight: .black, design: .rounded))
        }
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

    private var cardStack: some View {
        ZStack {
            ForEach(Array(app.pendingCrossings.prefix(3).enumerated()).reversed(),
                    id: \.element.id) { index, crossing in
                CrossingCardView(crossing: crossing,
                                 dragX: index == 0 ? dragOffset.width : 0)
                    .scaleEffect(index == 0 ? 1 : 1 - 0.04 * CGFloat(index))
                    .offset(y: CGFloat(index) * 12)
                    .offset(index == 0 ? dragOffset : .zero)
                    .rotationEffect(.degrees(index == 0 ? dragOffset.width / 18 : 0))
                    .gesture(dragGesture(for: crossing))
            }
        }
        .padding(.top, 4)
    }

    private func dragGesture(for crossing: Crossing) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard crossing.id == app.pendingCrossings.first?.id else { return }
                dragOffset = value.translation
            }
            .onEnded { value in
                guard crossing.id == app.pendingCrossings.first?.id else { return }
                if value.translation.width > 120 {
                    swipe(crossing, liked: true)
                } else if value.translation.width < -120 {
                    swipe(crossing, liked: false)
                } else {
                    withAnimation(.spring()) { dragOffset = .zero }
                }
            }
    }

    private func swipe(_ crossing: Crossing, liked: Bool) {
        withAnimation(.easeOut(duration: 0.25)) {
            dragOffset = CGSize(width: liked ? 600 : -600, height: -40)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if liked {
                app.like(crossing)
            } else {
                app.pass(crossing)
            }
            dragOffset = .zero
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 44) {
            Button {
                if let top = app.pendingCrossings.first { swipe(top, liked: false) }
            } label: {
                Image(systemName: "xmark")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.slate)
                    .frame(width: 60, height: 60)
                    .background(Theme.card, in: Circle())
                    .overlay(Circle().stroke(Theme.cardBorder, lineWidth: 1))
            }
            Button {
                if let top = app.pendingCrossings.first { swipe(top, liked: true) }
            } label: {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.onAccent)
                    .frame(width: 60, height: 60)
                    .background(Theme.primaryFill, in: Circle())
                    .shadow(color: Theme.accent.opacity(0.4), radius: 12, y: 4)
            }
        }
        .padding(.bottom, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "figure.run")
                .font(.system(size: 44))
                .foregroundStyle(Theme.accent)
            Text("No new crossings")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Text("Go for a run — anyone you cross paths with shows up here after your run syncs.")
                .font(.subheadline)
                .foregroundStyle(Theme.slate)
                .multilineTextAlignment(.center)
            if app.isLive {
                VoltButton(title: app.isSyncing ? "Syncing…" : "Sync Apple Watch runs") {
                    Task { await app.syncFromHealthKit() }
                }
                .disabled(app.isSyncing)
                .frame(width: 260)
                if let status = app.syncStatus {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(Theme.slate)
                        .multilineTextAlignment(.center)
                }
            } else {
                VoltButton(title: "Simulate a run sync") { app.syncDemoRun() }
                    .frame(width: 240)
            }
        }
        .padding(24)
    }
}
