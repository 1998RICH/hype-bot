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

            Button(action: advance) {
                Text(page == 3 ? "Start crossing paths" : "Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.brandGradient, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)
            }
            .padding(20)
        }
        .background(Theme.cloud)
    }

    private func advance() {
        if page < 3 {
            withAnimation { page += 1 }
        } else {
            let trimmed = name.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty { app.me.firstName = trimmed }
            app.me.age = age
            withAnimation { app.hasOnboarded = true }
        }
    }

    private var welcome: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.brandGradient)
                    .frame(width: 120, height: 120)
                Image(systemName: "figure.run")
                    .font(.system(size: 54, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text("Strideby")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(Theme.ink)
            Text("Cross paths. Match strides.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.orange)
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
                .font(.largeTitle.bold())
                .foregroundStyle(Theme.ink)
            stepRow(icon: "applewatch",
                    title: "Run like you always do",
                    detail: "Record with your Apple Watch or Garmin. No phone juggling, nothing extra to do.")
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
                .foregroundStyle(Theme.orange)
                .frame(width: 44, height: 44)
                .background(Theme.yellow.opacity(0.25), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
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
                .font(.largeTitle.bold())
                .foregroundStyle(Theme.ink)
            Text("Your runs sync automatically after each workout. Your exact route is never shown to other runners.")
                .font(.subheadline)
                .foregroundStyle(Theme.slate)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            watchButton(name: "Apple Watch", icon: "applewatch",
                        connected: app.appleWatchConnected) {
                app.appleWatchConnected.toggle()
            }
            watchButton(name: "Garmin", icon: "antenna.radiowaves.left.and.right",
                        connected: app.garminConnected) {
                app.garminConnected.toggle()
            }
            Text("Prototype note: connections are simulated for now.")
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
                        .foregroundStyle(.green)
                } else {
                    Text("Connect")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.orange)
                }
            }
            .padding(16)
            .background(.white, in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 28)
    }

    private var profileSetup: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            Text("About you")
                .font(.largeTitle.bold())
                .foregroundStyle(Theme.ink)
            Text("Just the basics — you can add photos and more later.")
                .font(.subheadline)
                .foregroundStyle(Theme.slate)
            TextField("First name", text: $name)
                .textFieldStyle(.plain)
                .padding(16)
                .background(.white, in: RoundedRectangle(cornerRadius: 16))
            Stepper("Age: \(age)", value: $age, in: 18...80)
                .padding(16)
                .background(.white, in: RoundedRectangle(cornerRadius: 16))
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
    }
}
