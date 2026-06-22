import SwiftUI

struct MatchCardView: View {
    let match: FeaturedMatch
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Home Team Area
                HStack(spacing: 10) {
                    Text(match.homeTeam)
                        .font(.system(size: 16, weight: .bold)) // Bigger, readable font size
                        .lineLimit(1)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    TeamLogoView(
                        teamName: match.homeTeam,
                        localSpreadsheetURL: match.homeFlagURL,
                        fallbackColor: match.homeFallbackColor,
                        initials: match.getTeamInitials(from: match.homeTeam),
                        size: 38 // Scaled up slightly for impact
                    )
                }
                .frame(maxWidth: .infinity)

                // Central Scoring Partition (Eye-capturing badge for scores)
                VStack(spacing: 4) {
                    if match.isCurrentlyLive || match.status.uppercased() == "FINISHED" {
                        Text(match.displayScore)
                            .font(.system(size: 22, weight: .black, design: .rounded)) // Bold, prominent score text
                            .monospacedDigit()
                            .foregroundColor(match.status.uppercased() == "FINISHED" ? .primary : .green)
                    } else {
                        Text(match.displayTime)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 75)

                // Away Team Area
                HStack(spacing: 10) {
                    TeamLogoView(
                        teamName: match.awayTeam,
                        localSpreadsheetURL: match.awayFlagURL,
                        fallbackColor: match.awayFallbackColor,
                        initials: match.getTeamInitials(from: match.awayTeam),
                        size: 38
                    )
                    
                    Text(match.awayTeam)
                        .font(.system(size: 16, weight: .bold)) // Bigger, readable font size
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 14)
            // Enhanced layout styling to make recent result cards pop beautifully
            .background(
                match.status.uppercased() == "FINISHED" 
                ? Color(.secondarySystemGroupedBackground) 
                : Color(.systemGray6)
            )
            .cornerRadius(16)
            .shadow(
                color: match.status.uppercased() == "FINISHED" 
                ? Color.green.opacity(0.12) 
                : Color.black.opacity(0.04), 
                radius: 8, x: 0, y: 4
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        match.status.uppercased() == "FINISHED" 
                        ? Color.green.opacity(0.3) 
                        : Color.clear, 
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
