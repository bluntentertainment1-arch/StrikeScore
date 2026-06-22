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

    // Resolves both direct raw URLs or fallback mappings
    var homeFlagURL: URL? {
        let clean = homeFlag.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("http") { return URL(string: clean) }
        if clean.count == 2 { return URL(string: "https://flagcdn.com/w80/\(clean.lowercased()).png") }
        return nil
    }

    var awayFlagURL: URL? {
        let clean = awayFlag.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("http") { return URL(string: clean) }
        if clean.count == 2 { return URL(string: "https://flagcdn.com/w80/\(clean.lowercased()).png") }
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

    // --- HIGH-FIDELITY AUTOMATED LOGO FALLBACK SYSTEM ---
    
    /// Generates a unique, stable color determined exclusively by the team name's characters
    func generateFallbackColor(for teamName: String) -> Color {
        let brandingPool: [Color] = [.red, .blue, .orange, .purple, .teal, .indigo, .pink, .cyan, .orange, .green]
        let characterSum = teamName.utf8.reduce(0) { $0 + Int($1) }
        return brandingPool[characterSum % brandingPool.count]
    }
    
    var homeFallbackColor: Color { generateFallbackColor(for: homeTeam) }
    var awayFallbackColor: Color { generateFallbackColor(for: awayTeam) }
    
    /// Derives uniform 2-character initials dynamically for emblem centers
    func getTeamInitials(from teamName: String) -> String {
        let cleanName = teamName.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = cleanName.components(separatedBy: " ")
        if words.count >= 2 {
            let firstInitial = words[0].prefix(1)
            let secondInitial = words[1].prefix(1)
            return "\(firstInitial)\(secondInitial)".uppercased()
        }
        return String(cleanName.prefix(2)).uppercased()
    }
}
