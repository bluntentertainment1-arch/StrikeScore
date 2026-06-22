import SwiftUI

struct MatchCardView: View {
    let match: FeaturedMatch 
    let onTap: () -> Void
    
    @StateObject private var favoritesManager = FavoritesManager.shared

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                // Home Team Area
                HStack(spacing: 6) {
                    Text(match.homeTeam)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    TeamLogoView(
                        teamName: match.homeTeam,
                        localSpreadsheetURL: match.homeFlagURL,
                        fallbackColor: match.homeFallbackColor,
                        initials: match.getTeamInitials(from: match.homeTeam),
                        size: 26
                    )
                }
                .frame(maxWidth: .infinity)

                // Central Scoring Partition
                VStack(spacing: 2) {
                    if match.isCurrentlyLive || match.status.uppercased() == "FINISHED" {
                        Text(match.displayScore)
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .monospacedDigit()
                    } else {
                        Text(match.displayTime)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    
                    if match.isCurrentlyLive {
                        Text(match.status)
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.red)
                    } else if match.status.uppercased() == "FINISHED" {
                        Text("FT")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 55)

                // Away Team Area
                HStack(spacing: 6) {
                    TeamLogoView(
                        teamName: match.awayTeam,
                        localSpreadsheetURL: match.awayFlagURL,
                        fallbackColor: match.awayFallbackColor,
                        initials: match.getTeamInitials(from: match.awayTeam),
                        size: 26
                    )
                    
                    Text(match.awayTeam)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
                
                // Inline Heart Trigger
                Button(action: {
                    favoritesManager.toggleFavorite(match.id)
                }) {
                    Image(systemName: favoritesManager.isFavorited(match.id) ? "heart.fill" : "heart")
                        .font(.system(size: 14))
                        .foregroundColor(favoritesManager.isFavorited(match.id) ? .red : .gray.opacity(0.6))
                        .padding(.leading, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .background(match.status.uppercased() == "FINISHED" ? Color(.systemBackground) : Color(.systemGray6))
            .cornerRadius(12)
            .shadow(color: match.status.uppercased() == "FINISHED" ? Color.black.opacity(0.03) : Color.clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
