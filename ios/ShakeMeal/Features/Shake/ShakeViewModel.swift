import Foundation
import Combine
import CoreLocation
import SwiftUI

@MainActor
final class ShakeViewModel: ObservableObject {
    // MARK: - State
    enum State: Equatable {
        case idle
        case loading
        case result(Restaurant)
        case error(String)
    }

    @Published var state: State = .idle
    @Published var filter: ShakeFilter = .default
    @Published var isFilterPresented = false

    private var cancellables = Set<AnyCancellable>()
    private let locationManager: LocationManager
    private let api: APIClient

    // Track recently seen place IDs to avoid immediate repeats
    private var recentlyExcluded: [String] = []
    private let maxExcluded = 10

    init(locationManager: LocationManager, api: APIClient = .shared) {
        self.locationManager = locationManager
        self.api = api
        listenForShake()
    }

    // MARK: - Shake Listener
    private func listenForShake() {
        ShakeDetector.shared.publisher
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.shake() }
            .store(in: &cancellables)
    }

    // MARK: - Actions
    func shake() {
        guard locationManager.hasPermission else {
            locationManager.requestPermission()
            return
        }
        guard locationManager.currentLocation != nil else {
            locationManager.requestLocation()
            state = .loading   // animated by ZStack's animation(value:) in ShakeView
            // Retry once location arrives
            locationManager.$currentLocation
                .compactMap { $0 }
                .first()
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in self?.fetchRandomRestaurant() }
                .store(in: &cancellables)
            return
        }
        fetchRandomRestaurant()
    }

    func shakeAgain() {
        // Exclude the current result so we always get something different
        if case .result(let current) = state {
            addToExcluded(current.id)
        }
        fetchRandomRestaurant()
    }

    func dismiss() {
        state = .idle   // animated by ZStack's animation(value:) in ShakeView
    }

    // MARK: - Fetch

    /// Minimum time (seconds) the loading/dice animation is shown.
    /// Ensures the animation plays even when the API responds instantly (e.g. mock).
    /// Has zero effect when the real API takes longer than this.
    private let minLoadingDisplay: TimeInterval = 0.85

    private func fetchRandomRestaurant() {
        guard let location = locationManager.currentLocation else { return }
        state = .loading   // animated by ZStack's animation(value:) in ShakeView
        let loadStart = Date()

        Task {
            do {
                let restaurant = try await api.shake(
                    lat: location.coordinate.latitude,
                    lng: location.coordinate.longitude,
                    filter: filter,
                    exclude: recentlyExcluded
                )
                // Keep the dice rolling for at least minLoadingDisplay seconds.
                let remaining = minLoadingDisplay - Date().timeIntervalSince(loadStart)
                if remaining > 0 {
                    try await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
                }
                // Plain assignment — withAnimation inside async Task is unreliable
                // and can be overridden by the dice timer's own animation transaction,
                // causing the card to flash in instead of sliding up.
                state = .result(restaurant)
            } catch APIError.noRestaurantsFound {
                state = .error("No restaurants found nearby.\nTry increasing your search radius.")
            } catch APIError.networkUnavailable {
                state = .error("No internet connection.\nPlease check your network and try again.")
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    private func addToExcluded(_ id: String) {
        recentlyExcluded.append(id)
        if recentlyExcluded.count > maxExcluded {
            recentlyExcluded.removeFirst()
        }
    }
}
