import Foundation

class LeagueTableService {
    static let shared = LeagueTableService()
    private init() {}
    
    func fetchLeagueTable(leagueId: String, season: String = "2025-2026") async -> [TableTeamEntry] {
        guard let url = URL(string: "https://www.thesportsdb.com/api/v1/json/123/lookuptable.php?l=\(leagueId)&s=\(season)") else {
            return []
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(SportsDBTableResponse.self, from: data)
            return response.table ?? []
        } catch {
            print("Failed to decode standings table: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - Decodable Standings Structures
struct SportsDBTableResponse: Codable {
    let table: [TableTeamEntry]?
}

struct TableTeamEntry: Codable, Identifiable, Hashable {
    var id: String { idTeam }
    
    let idTeam: String
    let strTeam: String
    let strTeamBadge: String?
    let intRank: String
    let intPlayed: String
    let intWin: String
    let intLoss: String
    let intDraw: String
    let intGoalsFor: String
    let intGoalsAgainst: String
    let intGoalDifference: String
    let intPoints: String
}
