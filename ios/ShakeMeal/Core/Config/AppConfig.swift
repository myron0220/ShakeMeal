import Foundation

enum AppConfig {
    // Switch baseURL here when deploying to Railway / Fly.io
    static let baseURL: URL = {
        // Fly.io backend — works on both simulator and real device
        // Switch back to http://localhost:8080 for local development
        return URL(string: "https://shakemeal-api.fly.dev")!
    }()
}
