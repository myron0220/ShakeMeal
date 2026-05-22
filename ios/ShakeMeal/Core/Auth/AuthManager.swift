import Foundation
import AuthenticationServices
import Combine

// MARK: - Models

struct TokenPair: Codable {
    let accessToken:  String
    let refreshToken: String
    let expiresIn:    Int

    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn    = "expires_in"
    }
}

struct AuthResponse: Codable {
    let user:   UserProfile
    let tokens: TokenPair
}

struct UserProfile: Codable, Equatable {
    let id:    String
    let email: String?
    let phone: String?
    let name:  String?
    let isPro: Bool

    enum CodingKeys: String, CodingKey {
        case id, email, phone, name
        case isPro = "is_pro"
    }
}

// MARK: - AuthManager

@MainActor
final class AuthManager: NSObject, ObservableObject {

    // MARK: Published state

    @Published var isSignedIn: Bool  = false
    @Published var isLoading:  Bool  = false
    @Published var user: UserProfile? = nil

    // MARK: Private

    private let api: APIClient

    private enum Key {
        static let accessToken  = "access_token"
        static let refreshToken = "refresh_token"
    }

    // MARK: Init

    init(api: APIClient = .shared) {
        self.api = api
        super.init()
        isSignedIn = KeychainHelper.load(forKey: Key.accessToken) != nil
    }

    // MARK: - Email / Phone + Password

    /// Register a new account. `identifier` is an email address or phone number.
    func register(identifier: String, password: String, name: String = "") async throws {
        isLoading = true
        defer { isLoading = false }
        var body: [String: String] = ["identifier": identifier, "password": password]
        if !name.isEmpty { body["name"] = name }
        let response: AuthResponse = try await api.post("/api/v1/auth/register", body: body)
        user = response.user
        persist(response.tokens)
    }

    /// Sign in with an existing email/phone + password account.
    func login(identifier: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        let response: AuthResponse = try await api.post(
            "/api/v1/auth/login",
            body: ["identifier": identifier, "password": password]
        )
        user = response.user
        persist(response.tokens)
    }

    // MARK: - Sign In With Apple

    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }

    /// Called by ProfileView when ASAuthorizationController completes successfully.
    func handleAuthorization(_ authorization: ASAuthorization) {
        guard let cred = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData     = cred.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8)
        else { return }

        let fullName = [cred.fullName?.givenName, cred.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        Task { @MainActor in
            isLoading = true
            defer { isLoading = false }
            do {
                let response: AuthResponse = try await api.post(
                    "/api/v1/auth/apple",
                    body: ["identity_token": identityToken, "full_name": fullName]
                )
                user = response.user
                persist(response.tokens)
            } catch {
                print("[AuthManager] Sign in with Apple failed:", error)
            }
        }
    }

    // MARK: - Sign Out

    func signOut() {
        KeychainHelper.delete(forKey: Key.accessToken)
        KeychainHelper.delete(forKey: Key.refreshToken)
        user       = nil
        isSignedIn = false
    }

    // MARK: - Token helpers (used by APIClient)

    var accessToken: String? {
        KeychainHelper.load(forKey: Key.accessToken)
    }

    /// Exchanges the stored refresh token for a new token pair.
    /// Throws `APIError.unauthorized` if no refresh token is available.
    func refreshTokens() async throws {
        guard let refresh = KeychainHelper.load(forKey: Key.refreshToken) else {
            throw APIError.unauthorized
        }
        let pair: TokenPair = try await api.post(
            "/api/v1/auth/refresh",
            body: ["refresh_token": refresh]
        )
        persist(pair)
    }

    // MARK: - Helpers

    private func persist(_ pair: TokenPair) {
        KeychainHelper.save(pair.accessToken,  forKey: Key.accessToken)
        KeychainHelper.save(pair.refreshToken, forKey: Key.refreshToken)
        isSignedIn = true
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthManager: ASAuthorizationControllerDelegate {

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let cred = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData  = cred.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8)
        else { return }

        let fullName = [cred.fullName?.givenName, cred.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        Task { @MainActor in
            isLoading = true
            defer { isLoading = false }
            do {
                let response: AuthResponse = try await api.post(
                    "/api/v1/auth/apple",
                    body: ["identity_token": identityToken, "full_name": fullName]
                )
                user = response.user
                persist(response.tokens)
            } catch {
                print("[AuthManager] Sign in with Apple failed:", error)
            }
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        // User cancelled or error — nothing to do
        print("[AuthManager] Sign in with Apple error:", error.localizedDescription)
    }
}
