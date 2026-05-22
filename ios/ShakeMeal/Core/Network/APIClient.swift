import Foundation

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let baseURL: URL

    init(baseURL: URL = AppConfig.baseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
        // No keyDecodingStrategy — all models use explicit CodingKeys for snake_case mapping.
        // convertFromSnakeCase conflicts with explicit CodingKeys (transforms keys before matching).
    }

    // MARK: - GET

    func get<T: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> T {
        let url = try buildURL(path: path, query: query)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        attachAuthHeader(&request)

        let (data, response) = try await perform(request)
        try validate(response: response, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }

    // MARK: - POST

    func post<T: Decodable>(_ path: String, body: [String: String]) async throws -> T {
        let url = try buildURL(path: path, query: [:])
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        request.httpBody = try JSONEncoder().encode(body)
        attachAuthHeader(&request)

        let (data, response) = try await perform(request)
        try validate(response: response, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }

    // MARK: - Shake endpoint

    func shake(lat: Double, lng: Double, filter: ShakeFilter, exclude: [String] = []) async throws -> Restaurant {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("/api/v1/shake"),
            resolvingAgainstBaseURL: false
        )!

        var items = [URLQueryItem]()
        items.append(URLQueryItem(name: "lat",    value: String(lat)))
        items.append(URLQueryItem(name: "lng",    value: String(lng)))
        items.append(URLQueryItem(name: "radius", value: String(filter.radiusMeters)))
        for cuisine in filter.cuisines  { items.append(URLQueryItem(name: "cuisine", value: cuisine)) }
        for price   in filter.priceLevels { items.append(URLQueryItem(name: "price", value: String(price))) }
        for id      in exclude          { items.append(URLQueryItem(name: "exclude", value: id)) }
        components.queryItems = items

        guard let url = components.url else { throw APIError.unknown(URLError(.badURL)) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        attachAuthHeader(&request)

        let (data, response) = try await perform(request)
        try validate(response: response, data: data)

        do {
            return try decoder.decode(Restaurant.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }

    // MARK: - Helpers

    private func attachAuthHeader(_ request: inout URLRequest) {
        if let token = KeychainHelper.load(forKey: "access_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    private func buildURL(path: String, query: [String: String]) throws -> URL {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else { throw APIError.unknown(URLError(.badURL)) }
        return url
    }

    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet {
            throw APIError.networkUnavailable
        } catch {
            throw APIError.unknown(error)
        }
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 404:
            if let body = try? JSONDecoder().decode(APIErrorBody.self, from: data),
               body.message.contains("no restaurants") {
                throw APIError.noRestaurantsFound
            }
            throw APIError.serverError(statusCode: 404, message: "Not found")
        default:
            let message = (try? JSONDecoder().decode(APIErrorBody.self, from: data))?.message
                          ?? "Server error (\(http.statusCode))"
            throw APIError.serverError(statusCode: http.statusCode, message: message)
        }
    }
}

// MARK: - Error body shape matching backend JSON
private struct APIErrorBody: Decodable {
    let message: String
}
