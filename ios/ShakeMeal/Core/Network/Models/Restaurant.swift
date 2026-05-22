import Foundation

struct Restaurant: Identifiable, Codable, Equatable {
    let id: String               // place_id from Google Places
    let name: String
    let address: String
    let cuisine: String
    let rating: Double           // 0.0 – 5.0
    let priceLevel: Int          // 1 – 4
    let photoURL: URL?
    let latitude: Double
    let longitude: Double
    let distanceMeters: Double?

    var priceDisplay: String {
        String(repeating: "$", count: priceLevel)
    }

    var distanceDisplay: String {
        guard let dist = distanceMeters else { return "" }
        if dist < 1000 {
            return String(format: "%.0fm away", dist)
        } else {
            return String(format: "%.1fkm away", dist / 1000)
        }
    }
}

// MARK: - Mock Data
extension Restaurant {
    static let mock = Restaurant(
        id: "mock-001",
        name: "Golden Dragon",
        address: "123 Main St, San Francisco, CA",
        cuisine: "Chinese",
        rating: 4.5,
        priceLevel: 2,
        photoURL: nil,
        latitude: 37.7749,
        longitude: -122.4194,
        distanceMeters: 350
    )

    static let mockList: [Restaurant] = [
        mock,
        Restaurant(id: "mock-002", name: "Sakura Ramen", address: "456 Oak Ave", cuisine: "Japanese",
                   rating: 4.8, priceLevel: 2, photoURL: nil, latitude: 37.775, longitude: -122.418, distanceMeters: 600),
        Restaurant(id: "mock-003", name: "Taco Loco", address: "789 Pine Rd", cuisine: "Mexican",
                   rating: 4.2, priceLevel: 1, photoURL: nil, latitude: 37.776, longitude: -122.420, distanceMeters: 900),
    ]
}
