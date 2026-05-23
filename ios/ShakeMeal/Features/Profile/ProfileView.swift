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
            .toolbarBackground(AppColors.surface.opacity(0.95), for: .navigationBar)
        }
    }
}

// MARK: - Signed-in view

private struct SignedInView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var store = SocialStore()

    var body: some View {
        List {
            // ── Profile header ───────────────────────────────────────
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppColors.textTertiary)

                    VStack(alignment: .leading, spacing: 4) {
                        if let name = authManager.user?.name, !name.isEmpty {
                            Text(name)
                                .font(AppFonts.heading)
                                .foregroundStyle(AppColors.textPrimary)
                        }
                        if let email = authManager.user?.email {
                            Text(email)
                                .font(AppFonts.meta)
                                .foregroundStyle(AppColors.textSecondary)
                        } else if let phone = authManager.user?.phone {
                            Text(phone)
                                .font(AppFonts.meta)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        if authManager.user?.isPro == true {
                            Label("Pro", systemImage: "star.fill")
                                .font(AppFonts.meta.bold())
                                .foregroundStyle(AppColors.star)
                        }
                    }
                }
                .padding(.vertical, 8)
                .listRowBackground(AppColors.surface)
            }

            // ── Favorites ────────────────────────────────────────────
            Section {
                if store.favoritesLoading {
                    HStack { Spacer(); ProgressView().tint(AppColors.textSecondary); Spacer() }
                        .listRowBackground(AppColors.surface)
                } else if store.favorites.isEmpty {
                    Text("No favorites yet — heart a restaurant after shaking!")
                        .font(AppFonts.meta)
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.vertical, 4)
                        .listRowBackground(AppColors.surface)
                } else {
                    ForEach(store.favorites.prefix(3)) { fav in
                        PlaceRow(
                            name:       fav.name,
                            subtitle:   fav.cuisine,
                            meta:       "\(fav.priceDisplay) · ★ \(String(format: "%.1f", fav.rating))",
                            systemIcon: "heart.fill",
                            iconColor:  AppColors.textSecondary
                        )
                        .listRowBackground(AppColors.surface)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                store.removeFavorite(placeID: fav.placeID)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                Label("Favorites", systemImage: "heart.fill")
                    .foregroundStyle(AppColors.textTertiary)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.8)
            }

            // ── History ──────────────────────────────────────────────
            Section {
                if store.historyLoading {
                    HStack { Spacer(); ProgressView().tint(AppColors.textSecondary); Spacer() }
                        .listRowBackground(AppColors.surface)
                } else if store.history.isEmpty {
                    Text("No history yet — start shaking!")
                        .font(AppFonts.meta)
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.vertical, 4)
                        .listRowBackground(AppColors.surface)
                } else {
                    ForEach(store.history.prefix(3)) { item in
                        PlaceRow(
                            name:       item.name,
                            subtitle:   item.cuisine,
                            meta:       item.shookAt.formatted(date: .abbreviated, time: .omitted),
                            systemIcon: "clock.fill",
                            iconColor:  AppColors.textTertiary
                        )
                        .listRowBackground(AppColors.surface)
                    }
                }
            } header: {
                Label("History", systemImage: "clock.fill")
                    .foregroundStyle(AppColors.textTertiary)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.8)
            }

            // ── Sign out ─────────────────────────────────────────────
            Section {
                Button(role: .destructive) {
                    authManager.signOut()
                } label: {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                            .font(AppFonts.button)
                            .foregroundStyle(Color(white: 1, opacity: 0.35))
                        Spacer()
                    }
                }
                .listRowBackground(AppColors.surface)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
        .listSectionSpacing(16)
        .refreshable { await store.load() }
        .task { await store.load() }
    }
}

// MARK: - Reusable place row

private struct PlaceRow: View {
    let name:       String
    let subtitle:   String
    let meta:       String
    let systemIcon: String
    let iconColor:  Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemIcon)
                .foregroundStyle(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
                Text(subtitle)
                    .font(AppFonts.meta)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            Text(meta)
                .font(AppFonts.meta)
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - SocialStore

@MainActor
final class SocialStore: ObservableObject {
    @Published var favorites:       [FavoriteItem] = []
    @Published var history:         [HistoryItem]  = []
    @Published var favoritesLoading = false
    @Published var historyLoading   = false

    private let api: APIClient

    init(api: APIClient = .shared) { self.api = api }

    func load() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadFavorites() }
            group.addTask { await self.loadHistory() }
        }
    }

    func loadFavorites() async {
        favoritesLoading = true
        defer { favoritesLoading = false }
        do { favorites = try await api.getFavorites() }
        catch { print("[SocialStore] favorites error:", error) }
    }

    func loadHistory() async {
        historyLoading = true
        defer { historyLoading = false }
        do { history = try await api.getHistory() }
        catch { print("[SocialStore] history error:", error) }
    }

    func removeFavorite(placeID: String) {
        Task {
            do {
                try await api.deleteFavorite(placeID: placeID)
                favorites.removeAll { $0.placeID == placeID }
            } catch {
                print("[SocialStore] remove favorite error:", error)
            }
        }
    }
}

// MARK: - Signed-out view

private struct SignedOutView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var identifier   = ""
    @State private var password     = ""
    @State private var name         = ""
    @State private var isRegister   = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer().frame(height: 12)

                Image(systemName: "person.circle")
                    .font(.system(size: 68))
                    .foregroundStyle(AppColors.textTertiary)

                Picker("", selection: $isRegister) {
                    Text("Sign In").tag(false)
                    Text("Register").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 32)

                VStack(spacing: 12) {
                    if isRegister {
                        TextField("Name (optional)", text: $name)
                            .textContentType(.name)
                            .autocorrectionDisabled()
                            .styledField()
                    }
                    TextField("Email or phone number", text: $identifier)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .styledField()

                    SecureField("Password (min 8 characters)", text: $password)
                        .textContentType(isRegister ? .newPassword : .password)
                        .styledField()
                }
                .padding(.horizontal, 32)

                if let msg = errorMessage {
                    Text(msg)
                        .font(AppFonts.meta)
                        .foregroundStyle(AppColors.warning)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Primary auth button — white capsule with dark text
                Button(action: submit) {
                    if authManager.isLoading {
                        ProgressView()
                            .tint(AppColors.background)
                    } else {
                        Text(isRegister ? "Create Account" : "Sign In")
                            .font(AppFonts.button)
                            .foregroundStyle(AppColors.background)  // dark text on white
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    identifier.isEmpty || password.isEmpty
                        ? AppColors.accent.opacity(0.35)
                        : AppColors.accent,
                    in: .capsule
                )
                .disabled(identifier.isEmpty || password.isEmpty || authManager.isLoading)
                .buttonStyle(PressButtonStyle())
                .padding(.horizontal, 32)

                // Divider
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(AppColors.textTertiary)
                    Text("or")
                        .font(AppFonts.meta)
                        .foregroundStyle(AppColors.textSecondary)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(AppColors.textTertiary)
                }
                .padding(.horizontal, 32)

                // Sign in with Apple — white style stands out on dark background
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let auth): authManager.handleAuthorization(auth)
                    case .failure(let err):  print("[ProfileView] Apple error:", err)
                    }
                }
                .signInWithAppleButtonStyle(.white)
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
                    try await authManager.register(identifier: identifier, password: password, name: name)
                } else {
                    try await authManager.login(identifier: identifier, password: password)
                }
            } catch let apiError as APIError {
                errorMessage = apiError.localizedDescription
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - TextField style

private extension View {
    func styledField() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppColors.surface, in: .rect(cornerRadius: 12))
            .font(AppFonts.body)
            .foregroundStyle(AppColors.textPrimary)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}
