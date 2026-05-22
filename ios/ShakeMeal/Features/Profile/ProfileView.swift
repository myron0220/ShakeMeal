import SwiftUI
import AuthenticationServices

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                if authManager.isSignedIn {
                    SignedInView()
                } else {
                    SignedOutView()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Signed-out state

private struct SignedOutView: View {
    @EnvironmentObject var authManager: AuthManager

    // Form state
    @State private var identifier  = ""   // email or phone
    @State private var password    = ""
    @State private var name        = ""   // register only
    @State private var isRegister  = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer().frame(height: 12)

                // Avatar
                Image(systemName: "person.circle")
                    .font(.system(size: 72))
                    .foregroundStyle(AppColors.textSecondary)

                // Tab toggle: Login / Register
                Picker("", selection: $isRegister) {
                    Text("Sign In").tag(false)
                    Text("Register").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 32)

                // Form
                VStack(spacing: 14) {
                    if isRegister {
                        TextField("Name (optional)", text: $name)
                            .textContentType(.name)
                            .autocorrectionDisabled()
                            .styledField()
                    }

                    TextField("Email or phone number", text: $identifier)
                        .textContentType(isRegister ? .username : .username)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .styledField()

                    SecureField("Password (min 8 characters)", text: $password)
                        .textContentType(isRegister ? .newPassword : .password)
                        .styledField()
                }
                .padding(.horizontal, 32)

                // Error
                if let msg = errorMessage {
                    Text(msg)
                        .font(AppFonts.meta)
                        .foregroundStyle(AppColors.warning)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Primary action button
                Button(action: submit) {
                    if authManager.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(isRegister ? "Create Account" : "Sign In")
                            .font(AppFonts.button)
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(identifier.isEmpty || password.isEmpty
                             ? AppColors.primary.opacity(0.4)
                             : AppColors.primary,
                             in: .capsule)
                .disabled(identifier.isEmpty || password.isEmpty || authManager.isLoading)
                .padding(.horizontal, 32)

                // Divider
                HStack {
                    Rectangle().frame(height: 1).foregroundStyle(AppColors.textSecondary.opacity(0.2))
                    Text("or").font(AppFonts.meta).foregroundStyle(AppColors.textSecondary)
                    Rectangle().frame(height: 1).foregroundStyle(AppColors.textSecondary.opacity(0.2))
                }
                .padding(.horizontal, 32)

                // Sign in with Apple (real device only)
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let auth): authManager.handleAuthorization(auth)
                    case .failure(let err):  print("[ProfileView] Apple sign-in error:", err)
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .cornerRadius(26)
                .padding(.horizontal, 32)

                Spacer().frame(height: 32)
            }
        }
    }

    private func submit() {
        errorMessage = nil
        Task {
            do {
                if isRegister {
                    try await authManager.register(identifier: identifier,
                                                   password: password,
                                                   name: name)
                } else {
                    try await authManager.login(identifier: identifier,
                                                password: password)
                }
            } catch let apiError as APIError {
                errorMessage = apiError.localizedDescription
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - TextField style helper

private extension View {
    func styledField() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppColors.card, in: .rect(cornerRadius: 12))
            .font(AppFonts.body)
    }
}

// MARK: - Signed-in state

private struct SignedInView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(AppColors.primary)

                if let name = authManager.user?.name, !name.isEmpty {
                    Text(name)
                        .font(AppFonts.heading)
                        .foregroundStyle(AppColors.textPrimary)
                }

                if let email = authManager.user?.email {
                    Text(email)
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textSecondary)
                } else if let phone = authManager.user?.phone {
                    Text(phone)
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textSecondary)
                }

                if authManager.user?.isPro == true {
                    Label("Pro", systemImage: "star.fill")
                        .font(AppFonts.meta.bold())
                        .foregroundStyle(AppColors.star)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(AppColors.star.opacity(0.15), in: .capsule)
                }
            }

            Spacer()

            Button(role: .destructive) {
                authManager.signOut()
            } label: {
                Text("Sign Out")
                    .font(AppFonts.button)
                    .foregroundStyle(AppColors.warning)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.warning.opacity(0.1), in: .capsule)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}
