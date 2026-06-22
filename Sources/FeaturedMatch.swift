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
        
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: matchDate) {
            // Include matches running within rolling window securely
            let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            return date > oneDayAgo
        }
        return true
    }

    // FIXED: Smart fallback string URL matching engine 
    var homeFlagURL: URL? {
        if homeFlag.hasPrefix("http") {
            return URL(string: homeFlag)
        }
        if homeFlag.count == 2 {
            return URL(string: "https://flagcdn.com/w80/\(homeFlag.lowercased()).png")
        }
        // If it's a structural name like "Bournemouth" or "Hull City", fall back to sports database
        let processedName = homeTeam.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        return URL(string: "https://media.api-sports.io/football/teams/\(processedName).png") ?? 
               URL(string: "https://flagcdn.com/w80/gb.png")
    }

    var awayFlagURL: URL? {
        if awayFlag.hasPrefix("http") {
            return URL(string: awayFlag)
        }
        if awayFlag.count == 2 {
            return URL(string: "https://flagcdn.com/w80/\(awayFlag.lowercased()).png")
        }
        let processedName = awayTeam.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        return URL(string: "https://media.api-sports.io/football/teams/\(processedName).png") ?? 
               URL(string: "https://flagcdn.com/w80/gb.png")
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
        if status == "TIMED" || homeScore.isEmpty || awayScore.isEmpty {
            return "vs"
        }
        return "\(homeScore) - \(awayScore)"
    }
}
