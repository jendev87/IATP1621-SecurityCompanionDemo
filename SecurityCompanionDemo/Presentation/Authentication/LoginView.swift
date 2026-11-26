//
//  LoginView.swift
//  SecurityCompanionDemo
//

import SwiftUI

struct LoginView: View {

    @Bindable var session: AuthSessionManager

    @State private var email: String = "alex.morgan@example.com"
    @State private var password: String = "password123"
    @State private var isPasswordVisible: Bool = false
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                // Security Logo
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 96, height: 96)

                    Image(systemName: "shield.checkered")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(.blue)
                }

                // Header
                VStack(spacing: 8) {
                    Text("Security Companion")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text("Sign in to monitor your security zones and connected sensors.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Form Fields
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                            .accessibilityHidden(true)
                        TextField("Email Address", text: $email)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .accessibilityLabel("Email Address")
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    )

                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                            .accessibilityHidden(true)

                        if isPasswordVisible {
                            TextField("Password", text: $password)
                                .textContentType(.password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .accessibilityLabel("Password")
                        } else {
                            SecureField("Password", text: $password)
                                .textContentType(.password)
                                .accessibilityLabel("Password")
                        }

                        Button {
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
                        .accessibilityValue(isPasswordVisible ? "Password visible" : "Password hidden")
                        .accessibilityHint(isPasswordVisible ? "Double tap to obscure password" : "Double tap to reveal password in plain text")
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    )
                }
                .padding(.horizontal, 24)

                // Sign In Button
                Button {
                    Task {
                        isLoading = true
                        // Brief natural delay for realistic simulation
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        isLoading = false
                        session.signIn()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 50)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(isLoading || email.isEmpty)
                .padding(.horizontal, 24)

                // Mock Session Notice
                Text("Demonstration Mode • Tap Sign In to proceed with pre-configured mock credentials.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()
                Spacer()
            }
            .padding()
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}

#Preview {
    LoginView(session: AuthSessionManager())
}
