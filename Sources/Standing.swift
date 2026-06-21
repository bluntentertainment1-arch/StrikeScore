import Foundation

struct StandingsResponse: Codable {
    let standings: [GroupStanding]
}

struct GroupStanding: Codable, Identifiable {
    let stage: String
    let type: String
    let group: String?
    let table: [TeamStanding]

    var id: String { "\(stage)-\(group ?? "overall")" }
    var displayGroup: String {
        group?.replacingOccurrences(of: "GROUP_", with: "Group ") ?? "Group"
    }
}

struct TeamStanding: Codable, Identifiable {
    let position: Int
    let team: Team
    let playedGames: Int
    let won: Int
    let draw: Int
    let lost: Int
    let goalsFor: Int
    let goalsAgainst: Int
    let goalDifference: Int
    let points: Int

    var id: Int { team.id }

    var isQualified: Bool {
        position <= 2
    }

    var isPossible: Bool {
        position == 3
    }
}
