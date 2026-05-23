import SwiftUI

@main
struct ShakeMealApp: App {
    @StateObject private var locationManager: LocationManager
    @StateObject private var shakeViewModel:  ShakeViewModel
    @StateObject private var authManager:     AuthManager

    init() {
        let lm = LocationManager()
        _locationManager = StateObject(wrappedValue: lm)
        _shakeViewModel  = StateObject(wrappedValue: ShakeViewModel(locationManager: lm))
        _authManager     = StateObject(wrappedValue: AuthManager())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(shakeViewModel)
                .environmentObject(authManager)
        }
    }
}
