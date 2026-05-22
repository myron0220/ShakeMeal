import Foundation
import Combine
import CoreLocation

@MainActor
final class ShakeViewModel: ObservableObject {
    // MARK: - State
    enum State {
        case idle           // waiting for shake
        case loading        // fetching restaurant
        case result(Restaurant)
        case error(String)
    }

    @Published var state: State = .idle
    @Published var filter: ShakeFilter = .default
    @Published var isFilterPresented = false

    private var cancellables = Set<AnyCancellable>()
    private let locationManager: LocationManager

    init(locationManager: LocationManager) {
        self.locationManager = locationManager
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
        fetchRandomRestaurant()
    }

    func shakeAgain() {
        fetchRandomRestaurant()
    }

    func dismiss() {
        state = .idle
    }

    // MARK: - Fetch
    private func fetchRandomRestaurant() {
        state = .loading

        // TODO: Replace with real API call
        // Simulating network delay with mock data
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2s
            let result = Restaurant.mockList.randomElement() ?? .mock
            self.state = .result(result)
        }
    }
}
