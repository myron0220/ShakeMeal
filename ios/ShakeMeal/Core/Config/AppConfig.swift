import Foundation

enum AppConfig {
    // Switch baseURL here when deploying to Railway / Fly.io
    static let baseURL: URL = {
        // Local dev — mock data, no database needed
        // Switch back to https://shakemeal-api.fly.dev for production
        return URL(string: "http://localhost:8080")!
    }()
}
