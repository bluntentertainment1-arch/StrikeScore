import SwiftUI

struct FeaturedMatchDetailView: View {
    let match: FeaturedMatch
    @Environment(\.dismiss) private var dismiss
    
    private var simulatedOdds: (home: String, draw: String, away: String) {
        let homeWeight = match.homeTeam.utf8.reduce(0) { $0 + Int($1) }
        let awayWeight = match.awayTeam.utf8.reduce(0) { $0 + Int($1) }
        
        let baseHome = 1.2 + Double(homeWeight % 250) / 100.0
        let baseAway = 1.2 + Double(awayWeight % 250) / 100.0
        let baseDraw = 2.1 + Double((homeWeight + awayWeight) % 150) / 100.0
        
        return (
            String(format: "%.2f", baseHome),
            String(format: "%.2f", baseDraw),
            String(format: "%.2f", baseAway)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Core Match Scoreboard Banner
                    VStack(spacing: 16) {
                        Text(match.competition)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            VStack(spacing: 8) {
                                TeamLogoView(
                                    teamName: match.homeTeam,
                                    localSpreadsheetURL: match.homeFlagURL,
                                    fallbackColor: match.homeFallbackColor,
                                    initials: match.getTeamInitials(from: match.homeTeam),
                                    size: 60
                                )
                                Text(match.homeTeam)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            
                            // Prominent Score Display
                            Text(match.displayScore)
                                .font(.system(size: 36, weight: .black, design: .rounded))
                            
                            VStack(spacing: 8) {
                                TeamLogoView(
                                    teamName: match.awayTeam,
                                    localSpreadsheetURL: match.awayFlagURL,
                                    fallbackColor: match.awayFallbackColor,
                                    initials: match.getTeamInitials(from: match.awayTeam),
                                    size: 60
                                )
                                Text(match.awayTeam)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // Simulated Betting Market Odds Display
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Simulated Full-Time Odds")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            OddsBox(label: "1 (Home)", value: simulatedOdds.home)
                            OddsBox(label: "X (Draw)", value: simulatedOdds.draw)
                            OddsBox(label: "2 (Away)", value: simulatedOdds.away)
                        }
                        .padding(.horizontal)
                    }

                    // FIXED: Key Match Information Card Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Match Information")
                            .font(.headline)
                        
                        Divider()
                        
                        Group {
                            // Added Match Status Info Field row 
                            InfoDetailRow(title: "Match Status", value: match.status.uppercased())
                                .foregroundColor(match.isCurrentlyLive ? .green : .primary)
                            
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
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Match Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
