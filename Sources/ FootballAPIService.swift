import Foundation

class FootballAPIService {
    static let shared = FootballAPIService()

    private var requestHeaders: [String: String] {
        [
            "X-Auth-Token": APIKey.footballData,
            "Content-Type": "application/json"
        ]
    }

    enum APIError: Error {
        case invalidURL
        case invalidResponse
        case rateLimited
        case decodingError
    }

    func fetchMatches(competition: String = AppConfig.defaultCompetition) async throws -> [Match] {
        guard let url = URL(string: "\(AppConfig.footballDataBaseURL)/competitions/\(competition)/matches") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = requestHeaders

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 429 {
            throw APIError.rateLimited
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        do {
            let decoded = try JSONDecoder().decode(MatchResponse.self, from: data)
            return decoded.matches
        } catch {
            throw APIError.decodingError
        }
    }

    func fetchStandings(competition: String = AppConfig.defaultCompetition) async throws -> [GroupStanding] {
        guard let url = URL(string: "\(AppConfig.footballDataBaseURL)/competitions/\(competition)/standings") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = requestHeaders

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(StandingsResponse.self, from: data)
        return decoded.standings
    }
}
