import SwiftUI

struct FeaturedMatchDetailView: View {
    let match: FeaturedMatch
    @Environment(\.dismiss) private var dismiss

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
                    
                    // --- DISPLAY ADVERTISEMENT BANNER CONTAINER ---
                    VStack(spacing: 6) {
                        // Dynamic frame fallback mapping standard AdMob/Inline display configurations safely
                        ZStack {
                            Color(.systemGray5)
                            
                            VStack(spacing: 4) {
                                Image(systemName: "rectangle.inset.filled.and.person.filled")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text("SPONSORED ADVERTISEMENT")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(height: 70) // Perfect matching allocation for standard banner dimensions
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Key Match Information Card Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Match Information")
                            .font(.headline)
                        
                        Divider()
                        
                        Group {
                            // Match Status row with explicit live tracking coloring
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

// MARK: - Helper Layout Components

struct InfoDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}
