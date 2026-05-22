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

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "person.circle")
                    .font(.system(size: 72))
                    .foregroundStyle(AppColors.textSecondary)

                Text("Sign in to sync your favorites and history across all your devices.")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            VStack(spacing: 16) {
                // Native Sign in with Apple button
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let auth):
                        authManager.handleAuthorization(auth)
                    case .failure(let error):
                        print("[ProfileView] Sign in with Apple failed:", error)
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .cornerRadius(26)
                .padding(.horizontal, 32)

                if authManager.isLoading {
                    ProgressView()
                }
            }
            .padding(.bottom, 48)
        }
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
