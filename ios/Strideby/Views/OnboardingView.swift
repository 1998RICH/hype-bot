import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var app: AppState
    @State private var page = 0
    @State private var name = ""
    @State private var age = 27

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                welcome.tag(0)
                howItWorks.tag(1)
                connectWatch.tag(2)
                profileSetup.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VoltButton(title: page == 3 ? "Start crossing paths" : "Continue",
                       action: advance)
                .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private func advance() {
        if page < 3 {
            withAnimation { page += 1 }
        } else {
            withAnimation {
                app.finishOnboarding(
                    name: name.trimmingCharacters(in: .whitespaces), age: age)
            }
        }
    }

    private var welcome: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.glow(Theme.orange, radius: 160))
                    .frame(width: 320, height: 320)
                Circle()
                    .fill(Theme.brandGradient)
                    .frame(width: 116, height: 116)
                Image(systemName: "figure.run")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text("Strideby")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("Cross paths. Match strides.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.accent)
            Text("The dating app where your next run is also your next chance to meet someone.")
                .font(.subheadline)
                .foregroundStyle(Theme.slate)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
            Spacer()
        }
    }

    private var howItWorks: some View {
        VStack(alignment: .leading, spacing: 28) {
            Spacer()
            Text("How it works")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            stepRow(icon: "iphone",
                    title: "Run like you always do",
                    detail: "Record with Strideby, your Apple Watch, or Garmin. Phone in your pocket is enough.")
            stepRow(icon: "arrow.triangle.swap",
                    title: "We spot your crossings",
                    detail: "When your run syncs, we find other Strideby runners whose path crossed yours — same place, same time.")
            stepRow(icon: "heart.fill",
                    title: "Like, match, chat",
                    detail: "It takes two likes to match. Then plan the next run together.")
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    private func stepRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Theme.accent)
                .frame(width: 46, height: 46)
                .background(Theme.accent.opacity(0.13), in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Theme.slate)
            }
        }
    }

    private var connectWatch: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Connect your watch")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("Optional — Strideby can record runs by itself. Your exact route is never shown to other runners.")
                .font(.subheadline)
                .foregroundStyle(Theme.slate)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            watchButton(name: "Apple Watch", icon: "applewatch",
                        connected: app.appleWatchConnected) {
                if app.isLive {
                    Task { @MainActor in
                        try? await HealthKitManager.shared.requestAuthorization()
                        app.appleWatchConnected = true
                    }
                } else {
                    app.appleWatchConnected.toggle()
                }
            }
            watchButton(name: "Garmin", icon: "antenna.radiowaves.left.and.right",
                        connected: app.garminConnected) {
                app.garminConnected.toggle()
            }
            Text(app.isLive
                 ? "Apple Watch works today. Garmin sync is coming next (via Terra)."
                 : "Prototype note: connections are simulated for now.")
                .font(.caption)
                .foregroundStyle(Theme.slate)
            Spacer()
            Spacer()
        }
    }

    private func watchButton(name: String, icon: String, connected: Bool,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                Text(name)
                    .font(.headline)
                Spacer()
                if connected {
                    Label("Connected", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                } else {
                    Text("Connect")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .foregroundStyle(.white)
            .padding(16)
            .glassCard(radius: 18)
        }
        .padding(.horizontal, 28)
    }

    private var profileSetup: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            Text("About you")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("Just the basics — you can add photos and more later.")
                .font(.subheadline)
                .foregroundStyle(Theme.slate)
            TextField("First name", text: $name)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .padding(16)
                .glassCard(radius: 16)
            Stepper("Age: \(age)", value: $age, in: 18...80)
                .foregroundStyle(.white)
                .padding(16)
                .glassCard(radius: 16)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
    }
}
