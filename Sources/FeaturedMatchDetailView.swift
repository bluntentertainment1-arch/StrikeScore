import SwiftUI

struct FeaturedMatchDetailView: View {
    let match: FeaturedMatch
    @Environment(\.dismiss) private var dismiss
    
    // --- RUNTIME DETERMINISTIC ODDS ENGINE ---
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
                                    .font(.headline)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Text(match.displayScore)
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .frame(width: 120)
                            
                            VStack(spacing: 8) {
                                TeamLogoView(
                                    teamName: match.awayTeam,
                                    localSpreadsheetURL: match.awayFlagURL,
                                    fallbackColor: match.awayFallbackColor,
                                    initials: match.getTeamInitials(from: match.awayTeam),
                                    size: 60
                                )
                                Text(match.awayTeam)
                                    .font(.headline)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    
                    // --- PRE-MATCH BETTING ODDS PANEL ---
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Match Odds")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            OddsBox(label: "1 (Home)", value: simulatedOdds.home)
                            OddsBox(label: "X (Draw)", value: simulatedOdds.draw)
                            OddsBox(label: "2 (Away)", value: simulatedOdds.away)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Info Row Metadata Block
                    VStack(spacing: 12) {
                        InfoDetailRow(title: "Venue", value: match.venue.isEmpty ? "Unknown Stadium" : match.venue)
                        InfoDetailRow(title: "Date", value: match.displayDate)
                        InfoDetailRow(title: "Time", value: match.displayTime)
                        if !match.stage.isEmpty {
                            InfoDetailRow(title: "Stage", value: match.stage)
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

struct OddsBox: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
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
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}
