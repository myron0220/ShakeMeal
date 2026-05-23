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
        name: "Kinton Ramen",
        address: "4026 Confederation Pkwy, Mississauga, ON",
        cuisine: "Japanese",
        rating: 4.4,
        priceLevel: 2,
        photoURLString: "https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=800",
        latitude: 43.5935,
        longitude: -79.6423,
        distanceMeters: 150,
        isOpen: true
    )

    static let mockList: [Restaurant] = [
        mock,
        Restaurant(id: "mock-002", name: "Osmow's Shawarma", address: "100 City Centre Dr, Mississauga, ON",
                   cuisine: "Middle Eastern", rating: 4.5, priceLevel: 1,
                   photoURLString: "https://images.unsplash.com/photo-1561043433-aaf687c4cf04?w=800",
                   latitude: 43.5920, longitude: -79.6440, distanceMeters: 280, isOpen: true),
        Restaurant(id: "mock-003", name: "Moxies", address: "100 City Centre Dr, Mississauga, ON",
                   cuisine: "Canadian", rating: 4.0, priceLevel: 3,
                   photoURLString: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800",
                   latitude: 43.5927, longitude: -79.6445, distanceMeters: 320, isOpen: true),
        Restaurant(id: "mock-006", name: "Punjabi By Nature", address: "2980 Drew Rd, Mississauga, ON",
                   cuisine: "Indian", rating: 4.3, priceLevel: 2,
                   photoURLString: "https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=800",
                   latitude: 43.7034, longitude: -79.6612, distanceMeters: 1800, isOpen: true),
        Restaurant(id: "mock-008", name: "El Catrin", address: "18 Tank House Lane, Toronto, ON",
                   cuisine: "Mexican", rating: 4.4, priceLevel: 3,
                   photoURLString: "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800",
                   latitude: 43.6503, longitude: -79.3610, distanceMeters: 5500, isOpen: true),
        Restaurant(id: "mock-009", name: "Khao San Road", address: "326 Adelaide St W, Toronto, ON",
                   cuisine: "Thai", rating: 4.5, priceLevel: 2,
                   photoURLString: "https://images.unsplash.com/photo-1562565652-a0d8f0c59eb4?w=800",
                   latitude: 43.6474, longitude: -79.3939, distanceMeters: 4300, isOpen: true),
    ]
}
