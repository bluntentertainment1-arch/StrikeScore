import Foundation

class FootballAPIService {
    static let shared = FootballAPIService()

    private var requestHeaders: [String: String] {
        [
            "x-apisports-key": APIKey.footballData
        ]
    }

    enum APIError: Error, LocalizedError {
        case invalidURL
        case invalidResponse
        case rateLimited
        case decodingError
        case networkError(Error)
        case httpError(Int, String)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid API URL"
            case .invalidResponse: return "Invalid response from server"
            case .rateLimited: return "Rate limit reached (100/day on free tier)"
            case .decodingError: return "Failed to decode API response"
            case .networkError(let error): return "Network error: \(error.localizedDescription)"
            case .httpError(let code, let message): return "HTTP \(code): \(message)"
            }
        }
    }

    func fetchMatches(league: Int = 1, season: Int = 2022) async throws -> [Match] {
        guard let url = URL(string: "https://v3.football.api-sports.io/fixtures?league=\(league)&season=\(season)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = requestHeaders
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        AppLogger.shared.log("HTTP Status: \(httpResponse.statusCode)")

        if httpResponse.statusCode == 429 {
            throw APIError.rateLimited
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "No body"
            throw APIError.httpError(httpResponse.statusCode, body)
        }

        do {
            let decoded = try JSONDecoder().decode(APIFixtureResponse.self, from: data)
            AppLogger.shared.log("Fetched \(decoded.response.count) fixtures")
            return decoded.response.map { $0.toMatch() }
        } catch {
            AppLogger.shared.error("Decoding error: \(error)")
            throw APIError.decodingError
        }
    }

    func fetchStandings(league: Int = 1, season: Int = 2022) async throws -> [GroupStanding] {
        guard let url = URL(string: "https://v3.football.api-sports.io/standings?league=\(league)&season=\(season)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = requestHeaders
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw APIError.httpError(status, "Standings request failed")
        }

        let decoded = try JSONDecoder().decode(APIStandingsResponse.self, from: data)
        return decoded.response.map { $0.toGroupStanding() }
    }
}

// MARK: - API Response Models

struct APIFixtureResponse: Codable {
    let response: [APIFixture]
}

struct APIFixture: Codable {
    let fixture: APIFixtureDetail
    let league: APIFixtureLeague
    let teams: APIFixtureTeams
    let goals: APIFixtureGoals?
    let score: APIFixtureScore?

    func toMatch() -> Match {
        let status: String
        switch fixture.status.short {
        case "FT": status = "FINISHED"
        case "NS": status = "SCHEDULED"
        case "1H", "2H", "HT", "ET", "P", "LIVE", "TBD": status = "IN_PLAY"
        default: status = fixture.status.short
        }

        return Match(
            id: fixture.id,
            utcDate: fixture.date,
            status: status,
            minute: fixture.status.elapsed,
            stage: league.round,
            group: nil,
            homeTeam: Team(
                id: teams.home.id,
                name: teams.home.name,
                shortName: nil,
                crest: teams.home.logo
            ),
            awayTeam: Team(
                id: teams.away.id,
                name: teams.away.name,
                shortName: nil,
                crest: teams.away.logo
            ),
            score: Score(
                fullTime: ScoreDetail(
                    home: goals?.home,
                    away: goals?.away
                ),
                halfTime: nil
            )
        )
    }
}

struct APIFixtureDetail: Codable {
    let id: Int
    let date: String
    let status: APIFixtureStatus
}

struct APIFixtureStatus: Codable {
    let short: String
    let elapsed: Int?
}

struct APIFixtureLeague: Codable {
    let round: String?
}

struct APIFixtureTeams: Codable {
    let home: APITeam
    let away: APITeam
}

struct APITeam: Codable {
    let id: Int
    let name: String
    let logo: String?
}

struct APIFixtureGoals: Codable {
    let home: Int?
    let away: Int?
}

struct APIFixtureScore: Codable {
    let halftime: APIScoreDetail?
    let fulltime: APIScoreDetail?
}

struct APIScoreDetail: Codable {
    let home: Int?
    let away: Int?
}

struct APIStandingsResponse: Codable {
    let response: [APIStandingGroup]
}

struct APIStandingGroup: Codable {
    let league: APIStandingLeague
}

struct APIStandingLeague: Codable {
    let standings: [[APIStandingTeam]]?
}

struct APIStandingTeam: Codable {
    let rank: Int
    let team: APITeam
    let all: APIStandingStats
    let goalsDiff: Int
    let points: Int

    func toTeamStanding() -> TeamStanding {
        return TeamStanding(
            position: rank,
            team: Team(
                id: team.id,
                name: team.name,
                shortName: nil,
                crest: team.logo
            ),
            playedGames: all.played,
            won: all.win,
            draw: all.draw,
            lost: all.lose,
            goalsFor: 0,
            goalsAgainst: 0,
            goalDifference: goalsDiff,
            points: points
        )
    }
}

struct APIStandingStats: Codable {
    let played: Int
    let win: Int
    let draw: Int
    let lose: Int
}

extension APIStandingGroup {
    func toGroupStanding() -> GroupStanding {
        let table = league.standings?.first ?? []
        return GroupStanding(
            stage: "GROUP_STAGE",
            type: "TOTAL",
            group: nil,
            table: table.map { $0.toTeamStanding() }
        )
    }
}
