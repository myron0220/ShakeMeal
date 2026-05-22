import SwiftUI

@main
struct ShakeMealApp: App {
    // Create LocationManager first, then pass it to ShakeViewModel
    // so both share the same instance throughout the app lifecycle.
    @StateObject private var locationManager: LocationManager
    @StateObject private var shakeViewModel: ShakeViewModel

    init() {
        let lm = LocationManager()
        _locationManager = StateObject(wrappedValue: lm)
        _shakeViewModel  = StateObject(wrappedValue: ShakeViewModel(locationManager: lm))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(shakeViewModel)
        }
    }
}
