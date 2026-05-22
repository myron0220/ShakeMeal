import Foundation

struct ShakeFilter: Codable, Equatable {
    var radiusMeters: Int = 1000
    var cuisines: [String] = []
    var priceLevels: [Int] = []

    static let `default` = ShakeFilter()

    var isDefault: Bool {
        self == .default
    }
}

enum CuisineType: String, CaseIterable, Identifiable {
    case japanese = "Japanese"
    case chinese = "Chinese"
    case italian = "Italian"
    case mexican = "Mexican"
    case american = "American"
    case thai = "Thai"
    case indian = "Indian"
    case korean = "Korean"
    case mediterranean = "Mediterranean"

    var id: String { rawValue }
    var emoji: String {
        switch self {
        case .japanese: return "🍣"
        case .chinese: return "🥡"
        case .italian: return "🍝"
        case .mexican: return "🌮"
        case .american: return "🍔"
        case .thai: return "🍜"
        case .indian: return "🍛"
        case .korean: return "🥩"
        case .mediterranean: return "🥙"
        }
    }
}
