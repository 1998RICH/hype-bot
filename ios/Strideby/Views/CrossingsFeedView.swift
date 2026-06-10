import SwiftUI

/// Bumble-style swipe deck, but every card is someone you actually
/// crossed paths with on a recent run.
struct CrossingsFeedView: View {
    @EnvironmentObject private var app: AppState
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if app.pendingCrossings.isEmpty {
                    emptyState
                } else {
                    cardStack
                    actionButtons
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 20)
            .background(Theme.cloud)
            .navigationTitle("Crossings")
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
        .padding(.top, 8)
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
                    .frame(width: 64, height: 64)
                    .background(.white, in: Circle())
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            }
            Button {
                if let top = app.pendingCrossings.first { swipe(top, liked: true) }
            } label: {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(Theme.brandGradient, in: Circle())
                    .shadow(color: Theme.orange.opacity(0.35), radius: 10, y: 4)
            }
        }
        .padding(.bottom, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "figure.run")
                .font(.system(size: 44))
                .foregroundStyle(Theme.orange)
            Text("No new crossings")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.ink)
            Text("Go for a run — anyone you cross paths with shows up here after your watch syncs.")
                .font(.subheadline)
                .foregroundStyle(Theme.slate)
                .multilineTextAlignment(.center)
            if app.isLive {
                Button(app.isSyncing ? "Syncing…" : "Sync Apple Watch runs") {
                    Task { await app.syncFromHealthKit() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(app.isSyncing)
                .padding(.top, 6)
                if let status = app.syncStatus {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(Theme.slate)
                        .multilineTextAlignment(.center)
                }
            } else {
                Button("Simulate a run sync") { app.syncDemoRun() }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 6)
            }
        }
        .padding(32)
    }
}
