import SwiftUI

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
    // Clean, generic properties mapping to the spreadsheet
    let link1: String?
    let link2: String?
    let link3: String?

    var isCurrentlyLive: Bool {
        return isLive || status.uppercased() == "LIVE" || status.uppercased() == "IN_PLAY"
    }

    var isVisible: Bool {
        guard active else { return false }
        if isCurrentlyLive { return true }
        
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: matchDate) {
            let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            return date > oneDayAgo
        }
        return true
    }

    var homeFlagURL: URL? {
        if homeFlag.hasPrefix("http") { return URL(string: homeFlag) }
        if homeFlag.count == 2 { return URL(string: "https://flagcdn.com/w80/\(homeFlag.lowercased()).png") }
        return nil
    }

    var awayFlagURL: URL? {
        if awayFlag.hasPrefix("http") { return URL(string: awayFlag) }
        if awayFlag.count == 2 { return URL(string: "https://flagcdn.com/w80/\(awayFlag.lowercased()).png") }
        return nil
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

    var displayTime: String { return matchTime }

    var displayScore: String {
        if status.uppercased() == "TIMED" || (homeScore.isEmpty && awayScore.isEmpty) {
            return "vs"
        }
        return "\(homeScore) - \(awayScore)"
    }

    // Checks if any target link values exist in the row cells
    var hasAdditionalContent: Bool {
        let l1 = link1?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let l2 = link2?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let l3 = link3?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !l1.isEmpty || !l2.isEmpty || !l3.isEmpty
    }

    func generateFallbackColor(for teamName: String) -> Color {
        let colors: [Color] = [.red, .blue, .orange, .purple, .teal, .indigo, .pink, .cyan, .orange, .green]
        let sum = teamName.utf8.reduce(0) { $0 + Int($1) }
        return colors[sum % colors.count]
    }
    
    var homeFallbackColor: Color { generateFallbackColor(for: homeTeam) }
    var awayFallbackColor: Color { generateFallbackColor(for: awayTeam) }
    
    func getTeamInitials(from teamName: String) -> String {
        let cleanName = teamName.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = cleanName.components(separatedBy: " ")
        if words.count >= 2 {
            let first = words[0].prefix(1)
            let second = words[1].prefix(1)
            return "\(first)\(second)".uppercased()
        }
        return String(cleanName.prefix(2)).uppercased()
    }
}
