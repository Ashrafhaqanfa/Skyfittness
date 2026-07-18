//
//  LoginView.swift
//  GymApp
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService

    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignUpMode = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor)

                Text("Gym Manager")
                    .font(.largeTitle.bold())

                VStack(spacing: 12) {
                    if isSignUpMode {
                        TextField("Your name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal, 32)

                if let error = authService.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 32)
                }

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
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text(isSignUpMode ? "Create Owner Account" : "Sign In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 32)
                .disabled(email.isEmpty || password.isEmpty || authService.isLoading)

                Button(isSignUpMode ? "Already have an account? Sign in" : "First time setup? Create owner account") {
                    isSignUpMode.toggle()
                    authService.errorMessage = nil
                }
                .font(.footnote)

                Spacer()
                Spacer()
            }
        }
    }
}

#Preview {
    LoginView().environmentObject(AuthService())
}
