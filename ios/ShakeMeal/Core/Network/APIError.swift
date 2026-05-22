import Foundation

enum APIError: LocalizedError {
    case noRestaurantsFound
    case networkUnavailable
    case serverError(statusCode: Int, message: String)
    case decodingFailed
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .noRestaurantsFound:
            return "No restaurants found nearby. Try increasing your search radius."
        case .networkUnavailable:
            return "No internet connection. Please check your network and try again."
        case .serverError(_, let message):
            return message
        case .decodingFailed:
            return "Something went wrong parsing the response."
        case .unknown(let err):
            return err.localizedDescription
        }
    }
}
