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
                Circle().fill(Theme.brandGradient).frame(width: 84, height: 84)
                Image(systemName: "figure.run")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text("Strideby")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(Theme.ink)

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
                    .padding(14)
                    .background(.white, in: RoundedRectangle(cornerRadius: 14))
            }

            if let error = app.authError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button(action: submit) {
                Text(busy ? "One moment…"
                          : (isRegistering ? "Create account" : "Log in"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.brandGradient,
                                in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)
            }
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.6)
            Spacer()
        }
        .padding(24)
        .background(Theme.cloud)
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
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: 14))
    }
}
