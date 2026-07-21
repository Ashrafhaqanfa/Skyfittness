//
//  LoginView.swift
//  GymApp
//
//  Redesigned to match the "GoGym4U" reference: banner header, Existing/New
//  segmented toggle, icon-prefixed fields, Remember Me, Forgot Password,
//  and a Google sign-in button.
//
//  NOTE ON SCOPE: "Continue with Google" is shown here as a real, tappable
//  button, but it currently just surfaces a friendly message rather than
//  actually signing you in. Wiring it up for real needs the GoogleSignIn SDK
//  added as a package dependency plus an OAuth client ID configured in the
//  Firebase console — that's an infrastructure step outside this file, not
//  something that can be faked in code. Ask me if you want to set that up.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService

    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignUpMode = false
    @State private var rememberMe = false
    @State private var showPassword = false
    @State private var showGoogleComingSoon = false
    @State private var showForgotPassword = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerBanner
                        .padding(.bottom, 20)

                    modeToggle
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)

                    formCard
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .scrollDismissesKeyboard(.interactively)
            .alert("Coming soon", isPresented: $showGoogleComingSoon) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Google sign-in needs a one-time setup in the Firebase console (OAuth client ID) before it can work. Ask your developer to enable it.")
            }
            .alert("Forgot password", isPresented: $showForgotPassword) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Enter your email above, then contact your gym's super admin, or use Firebase's password reset email flow.")
            }
        }
    }

    // MARK: - Header

    private var headerBanner: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color.black.opacity(0.55), Color.black.opacity(0.25)],
                startPoint: .bottom,
                endPoint: .top
            )
            .background(
                LinearGradient(
                    colors: [Color(red: 0.15, green: 0.17, blue: 0.22), Color(red: 0.32, green: 0.36, blue: 0.42)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .center) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 90))
                    .foregroundStyle(.white.opacity(0.12))
                    .rotationEffect(.degrees(-20))
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 0))

            HStack(alignment: .center, spacing: 14) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white)
                    .frame(width: 54, height: 54)
                    .overlay(
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                    )
                    .shadow(radius: 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Gym Admin Portal")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("Manage members, collection, expenses, plans & reports and much more.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                }
            }
            .padding(20)
        }
        .frame(height: 220)
        .clipped()
    }

    // MARK: - Existing / New toggle

    private var modeToggle: some View {
        HStack(spacing: 8) {
            modeButton(title: "Existing", systemImage: "lock.fill", isSelected: !isSignUpMode) {
                withAnimation(.snappy) { isSignUpMode = false }
                authService.errorMessage = nil
            }
            modeButton(title: "New", systemImage: "person.badge.plus", isSelected: isSignUpMode) {
                withAnimation(.snappy) { isSignUpMode = true }
                authService.errorMessage = nil
            }
        }
        .padding(4)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(Capsule())
    }

    private func modeButton(title: String, systemImage: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title.uppercased(), systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
        }
        .background(isSelected ? Color.accentColor.opacity(0.15) : .clear)
        .clipShape(Capsule())
    }

    // MARK: - Form card

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(isSignUpMode ? "Create Admin account" : "Sign in")
                    .font(.title3.bold())
                Text(isSignUpMode ? "Register admin/owner account." : "Use admin credentials to continue.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Label("Manage members, payments, attendance and more", systemImage: "checkmark.seal.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(Capsule())

            VStack(spacing: 12) {
                if isSignUpMode {
                    iconField(icon: "person.fill", placeholder: "Full Name", text: $name)
                }
                iconField(
                    icon: isSignUpMode ? "envelope.fill" : "person.fill",
                    placeholder: isSignUpMode ? "Email" : "Email / Mobile No.",
                    text: $email,
                    keyboard: .emailAddress
                )
                secureField(icon: "lock.fill", placeholder: "Password", text: $password)
            }

            if !isSignUpMode {
                Toggle(isOn: $rememberMe) {
                    Text("Remember Me").font(.subheadline)
                }
                .toggleStyle(.checkbox)
            }

            if let error = authService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            primaryButton

            if !isSignUpMode {
                Button("Forgot Password?") { showForgotPassword = true }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)

                HStack {
                    Rectangle().fill(Color(.separator)).frame(height: 1)
                    Text("OR").font(.caption).foregroundStyle(.secondary)
                    Rectangle().fill(Color(.separator)).frame(height: 1)
                }

                Button {
                    showGoogleComingSoon = true
                } label: {
                    Label("Continue with Google", systemImage: "g.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .background(Color(red: 0.85, green: 0.4, blue: 0.25))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack(spacing: 4) {
                Spacer()
                Text(isSignUpMode ? "Already have an account?" : "Don't have an account?")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button(isSignUpMode ? "Login Now" : "Register Now") {
                    withAnimation(.snappy) { isSignUpMode.toggle() }
                    authService.errorMessage = nil
                }
                .font(.footnote.weight(.semibold))
                Spacer()
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    private var primaryButton: some View {
        Button {
            Task {
                if isSignUpMode {
                    await authService.signUp(name: name, email: email, password: password)
                } else {
                    await authService.signIn(email: email, password: password)
                }
            }
        } label: {
            if authService.isLoading {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, 4)
            } else {
                Text(isSignUpMode ? "Register" : "Sign In")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(email.isEmpty || password.isEmpty || (isSignUpMode && name.isEmpty) || authService.isLoading)
    }

    // MARK: - Field helpers

    private func iconField(icon: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(Color.accentColor).frame(width: 20)
            TextField(placeholder, text: text)
                .textInputAutocapitalization(.never)
                .keyboardType(keyboard)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func secureField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(Color.accentColor).frame(width: 20)
            Group {
                if showPassword {
                    TextField(placeholder, text: text)
                } else {
                    SecureField(placeholder, text: text)
                }
            }
            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// A simple checkbox-style toggle so "Remember Me" reads like the reference design
// instead of an iOS switch.
private struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundStyle(configuration.isOn ? Color.accentColor : .secondary)
                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}

private extension ToggleStyle where Self == CheckboxToggleStyle {
    static var checkbox: CheckboxToggleStyle { CheckboxToggleStyle() }
}

#Preview {
    LoginView().environmentObject(AuthService())
}
