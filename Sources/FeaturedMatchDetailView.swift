import SwiftUI

struct FeaturedMatchDetailView: View {
    let match: FeaturedMatch
    @Environment(\.dismiss) private var dismiss
    @StateObject private var favoritesManager = FavoritesManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    
                    // Compact Scoreboard Banner Row
                    VStack(spacing: 12) {
                        Text(match.competition)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            // Home Team
                            VStack(spacing: 6) {
                                TeamLogoView(
                                    teamName: match.homeTeam,
                                    localSpreadsheetURL: match.homeFlagURL,
                                    fallbackColor: match.homeFallbackColor,
                                    initials: match.getTeamInitials(from: match.homeTeam),
                                    size: 44
                                )
                                Text(match.homeTeam)
                                    .font(.system(size: 13, weight: .bold))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.85)
                            }
                            .frame(maxWidth: .infinity)
                            
                            // Center Score Block
                            Text(match.displayScore)
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .frame(width: 70)
                            
                            // Away Team
                            VStack(spacing: 6) {
                                TeamLogoView(
                                    teamName: match.awayTeam,
                                    localSpreadsheetURL: match.awayFlagURL,
                                    fallbackColor: match.awayFallbackColor,
                                    initials: match.getTeamInitials(from: match.awayTeam),
                                    size: 44
                                )
                                Text(match.awayTeam)
                                    .font(.system(size: 13, weight: .bold))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.85)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6).opacity(0.6))
                    .cornerRadius(14)
                    .padding(.horizontal)

                    // Core Meta Details List Container
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Match Information")
                            .font(.system(size: 15, weight: .bold))
                        
                        Divider()
                        
                        Group {
                            InfoDetailRow(title: "Match Status", value: match.status.uppercased())
                                .foregroundColor(match.isCurrentlyLive ? .red : .primary)
                            
                            InfoDetailRow(title: "Date", value: match.matchDate)
                            InfoDetailRow(title: "Time", value: match.matchTime)
                            
                            if !match.venue.isEmpty {
                                InfoDetailRow(title: "Venue", value: match.venue)
                            }
                            if !match.group.isEmpty {
                                InfoDetailRow(title: "Group", value: match.group)
                            }
                            if !match.stage.isEmpty {
                                InfoDetailRow(title: "Stage", value: match.stage)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Match Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                
                // Persistent Top Bar Favorite Button Toggle Engine
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        favoritesManager.toggleFavorite(match.id)
                    }) {
                        Image(systemName: favoritesManager.isFavorited(match.id) ? "heart.fill" : "heart")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(favoritesManager.isFavorited(match.id) ? .red : .primary)
                    }
                }
            }
        }
    }
}

struct InfoDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.system(size: 13))
    }
}
