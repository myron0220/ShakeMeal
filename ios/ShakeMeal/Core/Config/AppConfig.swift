import Foundation

enum AppConfig {
    static let baseURL: URL = {
        switch mode {
        case .local:
            // Simulator only — backend on same Mac
            return URL(string: "http://localhost:8080")!
        case .tailscale:
            // WSL2 backend exposed via `tailscale serve https / http://localhost:8080`
            // Replace with your actual Tailscale HTTPS hostname:
            //   tailscale serve https / http://localhost:8080
            // then copy the printed URL here.
            return URL(string: "https://REPLACE-WITH-YOUR-TAILSCALE-HOSTNAME.ts.net")!
        case .production:
            return URL(string: "https://shakemeal-api.fly.dev")!
        }
    }()

    // ── Switch mode here ────────────────────────────────────────────────────
    private static let mode: Mode = .local

    private enum Mode { case local, tailscale, production }
}
