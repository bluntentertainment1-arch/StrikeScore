import SwiftUI

extension FeaturedMatch {
    // Generates a deterministically unique color based on the team's text characters
    func generateFallbackColor(for teamName: String) -> Color {
        let colors: [Color] = [.red, .blue, .orange, .purple, .teal, .indigo, .pink, .indigo, .cyan, Color.green]
        let sum = teamName.utf8.reduce(0) { $0 + Int($1) }
        return colors[sum % colors.count]
    }
    
    var homeFallbackColor: Color { generateFallbackColor(for: homeTeam) }
    var awayFallbackColor: Color { generateFallbackColor(for: awayTeam) }
    
    // Returns the first two letters of the team name capitalized (e.g., "Chelsea" -> "CH")
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
