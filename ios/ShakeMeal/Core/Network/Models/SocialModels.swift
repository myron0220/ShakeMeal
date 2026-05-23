import Foundation

// MARK: - Favorite

struct FavoriteItem: Identifiable, Codable, Equatable {
    let id:         String
    let placeID:    String
    let name:       String
    let address:    String
    let cuisine:    String
    let rating:     Double
    let priceLevel: Int
    let latitude:   Double
    let longitude:  Double
    let createdAt:  Date

    enum CodingKeys: String, CodingKey {
        case id, name, address, cuisine, rating, latitude, longitude
        case placeID    = "place_id"
        case priceLevel = "price_level"
        case createdAt  = "created_at"
    }

    var priceDisplay: String { String(repeating: "$", count: max(priceLevel, 1)) }
}

struct FavoritesResponse: Decodable {
    let favorites: [FavoriteItem]
}

// MARK: - History

struct HistoryItem: Identifiable, Codable, Equatable {
    let id:         String
    let placeID:    String
    let name:       String
    let address:    String
    let cuisine:    String
    let rating:     Double
    let priceLevel: Int
    let latitude:   Double
    let longitude:  Double
    let shookAt:    Date

    enum CodingKeys: String, CodingKey {
        case id, name, address, cuisine, rating, latitude, longitude
        case placeID    = "place_id"
        case priceLevel = "price_level"
        case shookAt    = "shook_at"
    }

    var priceDisplay: String { String(repeating: "$", count: max(priceLevel, 1)) }
}

struct HistoryResponse: Decodable {
    let history: [HistoryItem]
}
