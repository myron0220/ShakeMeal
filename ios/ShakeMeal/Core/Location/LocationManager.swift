import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    /// Human-readable street address from the last known location.
    /// nil until the first reverse-geocode completes (or if permission is denied).
    @Published var placeName: String?
    @Published var error: LocationError?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var hasPermission: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        guard hasPermission else {
            requestPermission()
            return
        }
        manager.requestLocation()
    }

    // MARK: - Reverse geocoding

    private func reverseGeocode(_ location: CLLocation) {
        Task {
            do {
                let marks = try await geocoder.reverseGeocodeLocation(location)
                guard let mark = marks.first else { return }
                // Prefer "3900 Confederation Pkwy", fall back to just the street,
                // then the city, then the raw placemark name.
                let parts = [mark.subThoroughfare, mark.thoroughfare].compactMap { $0 }
                placeName = parts.isEmpty
                    ? (mark.locality ?? mark.name)
                    : parts.joined(separator: " ")
            } catch {
                // silently ignore — nav bar falls back to "ShakeMeal"
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
            self.reverseGeocode(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        Task { @MainActor in
            self.error = .failed(error.localizedDescription)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse {
                manager.requestLocation()
            }
        }
    }
}

// MARK: - Errors
enum LocationError: LocalizedError {
    case permissionDenied
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "Location access denied. Please enable it in Settings."
        case .failed(let msg): return msg
        }
    }
}
