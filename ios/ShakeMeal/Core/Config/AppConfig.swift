import Foundation

enum AppConfig {
    // Switch baseURL here when deploying to Railway / Fly.io
    static let baseURL: URL = {
        #if DEBUG
        // Local Go backend — run `make run` in /backend
        return URL(string: "http://localhost:8080")!
        #else
        return URL(string: "https://shakemeal-api.fly.dev")!   // Fly.io production
        #endif
    }()
}
