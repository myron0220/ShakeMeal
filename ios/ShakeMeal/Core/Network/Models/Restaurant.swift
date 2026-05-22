import Foundation

struct Restaurant: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let address: String
    let cuisine: String
    let rating: Double
    let priceLevel: Int
    private let photoURLString: String?   // raw string from JSON — may be nil or empty
    let latitude: Double
    let longitude: Double
    let distanceMeters: Double?
    let isOpen: Bool?

    /// Resolved photo URL — nil when backend sends no photo.
    var photoURL: URL? {
        guard let s = photoURLString, !s.isEmpty else { return nil }
        return URL(string: s)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, address, cuisine, rating, latitude, longitude
        case priceLevel     = "price_level"
        case photoURLString = "photo_url"
        case distanceMeters = "distance_meters"
        case isOpen         = "is_open"
    }

    var priceDisplay: String {
        String(repeating: "$", count: max(priceLevel, 1))
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
        photoURLString: nil,
        latitude: 37.7749,
        longitude: -122.4194,
        distanceMeters: 350,
        isOpen: true
    )

    static let mockList: [Restaurant] = [
        mock,
        Restaurant(id: "mock-002", name: "Sakura Ramen", address: "456 Oak Ave",
                   cuisine: "Japanese", rating: 4.8, priceLevel: 2,
                   photoURLString: nil, latitude: 37.775, longitude: -122.418,
                   distanceMeters: 600, isOpen: true),
        Restaurant(id: "mock-003", name: "Taco Loco", address: "789 Pine Rd",
                   cuisine: "Mexican", rating: 4.2, priceLevel: 1,
                   photoURLString: nil, latitude: 37.776, longitude: -122.420,
                   distanceMeters: 900, isOpen: nil),
    ]
}
