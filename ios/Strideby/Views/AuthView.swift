import SwiftUI

/// Account creation / login — shown in live mode after onboarding.
struct AuthView: View {
    @EnvironmentObject private var app: AppState
    @State private var isRegistering = true
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var age = 27
    @State private var busy = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.glow(Theme.orange, radius: 120))
                    .frame(width: 240, height: 240)
                Circle()
                    .fill(Theme.brandGradient)
                    .frame(width: 80, height: 80)
                Image(systemName: "figure.run")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(height: 130)
            Text("Strideby")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Picker("Mode", selection: $isRegistering) {
                Text("Sign up").tag(true)
                Text("Log in").tag(false)
            }
            .pickerStyle(.segmented)
            .padding(.top, 8)

            field {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            field {
                SecureField("Password (8+ characters)", text: $password)
            }
            if isRegistering {
                field { TextField("First name", text: $firstName) }
                Stepper("Age: \(age)", value: $age, in: 18...80)
                    .foregroundStyle(.white)
                    .padding(14)
                    .glassCard(radius: 16)
            }

            if let error = app.authError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            VoltButton(title: busy ? "One moment…"
                              : (isRegistering ? "Create account" : "Log in"),
                       action: submit)
                .disabled(!canSubmit)
                .opacity(canSubmit ? 1 : 0.55)
            Spacer()
        }
        .padding(24)
        .background(Theme.bg.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private var canSubmit: Bool {
        !busy && email.contains("@") && password.count >= 8
            && (!isRegistering || !firstName.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    private func submit() {
        busy = true
        Task { @MainActor in
            await app.authenticate(register: isRegistering,
                                   email: email,
                                   password: password,
                                   firstName: firstName,
                                   age: age)
            busy = false
        }
    }

    private func field<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .foregroundStyle(.white)
            .padding(14)
            .glassCard(radius: 16)
    }
}
