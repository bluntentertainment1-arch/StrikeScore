import Foundation

struct FeaturedMatch: Identifiable, Codable, Hashable {
    let id: String
    let homeTeam: String
    let awayTeam: String
    let homeFlag: String
    let awayFlag: String
    let competition: String
    let matchDate: String
    let matchTime: String
    let venue: String
    let group: String
    let stage: String
    let homeScore: String
    let awayScore: String
    let status: String
    let isLive: Bool
    let priority: Int
    let active: Bool

    var isVisible: Bool {
        guard active else { return false }
        if isLive { return true }
        // Don't show matches that ended more than 1 day ago
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: matchDate) {
            let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            return date > oneDayAgo
        }
        return true
    }

    var homeFlagURL: URL? {
        if homeFlag.hasPrefix("http") {
            return URL(string: homeFlag)
        }
        return URL(string: "https://flagcdn.com/w80/\(homeFlag.lowercased()).png")
    }

    var awayFlagURL: URL? {
        if awayFlag.hasPrefix("http") {
            return URL(string: awayFlag)
        }
        return URL(string: "https://flagcdn.com/w80/\(awayFlag.lowercased()).png")
    }

    var displayDate: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: matchDate) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "EEE, MMM d"
            return displayFormatter.string(from: date)
        }
        return matchDate
    }

    var displayTime: String {
        return matchTime
    }

    var displayScore: String {
        if isLive || status == "FINISHED" {
            return "\(homeScore) - \(awayScore)"
        }
        return "vs"
    }
}
