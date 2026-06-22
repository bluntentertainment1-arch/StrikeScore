import SwiftUI

struct MatchCardView: View {
    let match: FeaturedMatch // Directly binding your comprehensive object data fields
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Home Team Area
                HStack(spacing: 8) {
                    Text(match.homeTeam)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    TeamLogoView(
                        teamName: match.homeTeam,
                        localSpreadsheetURL: match.homeFlagURL,
                        fallbackColor: match.homeFallbackColor,
                        initials: match.getTeamInitials(from: match.homeTeam),
                        size: 34
                    )
                }
                .frame(maxWidth: .infinity)

                // Central Scoring Partition (Pops FT score states cleanly)
                VStack(spacing: 4) {
                    if match.isCurrentlyLive || match.status.uppercased() == "FINISHED" {
                        Text(match.displayScore)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .monospacedDigit()
                    } else {
                        Text(match.displayTime)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                    }

                    if match.isCurrentlyLive {
                        Text("LIVE")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    } else if match.status.uppercased() == "FINISHED" {
                        Text("FT")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 65)

                // Away Team Area
                HStack(spacing: 8) {
                    TeamLogoView(
                        teamName: match.awayTeam,
                        localSpreadsheetURL: match.awayFlagURL,
                        fallbackColor: match.awayFallbackColor,
                        initials: match.getTeamInitials(from: match.awayTeam),
                        size: 34
                    )
                    
                    Text(match.awayTeam)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(match.status.uppercased() == "FINISHED" ? Color(.systemBackground) : Color(.systemGray6))
            .cornerRadius(16)
            .shadow(color: match.status.uppercased() == "FINISHED" ? Color.black.opacity(0.04) : Color.clear, radius: 6, x: 0, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(match.status.uppercased() == "FINISHED" ? Color(.systemGray4).opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
