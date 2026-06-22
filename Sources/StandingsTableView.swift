import SwiftUI

struct StandingsTableView: View {
    @StateObject private var leagueService = LeagueTableService()
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Table Header Column Labels
                HStack(spacing: 0) {
                    Text("#")
                        .frame(width: 30, alignment: .leading)
                    Text("Team")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("P")
                        .frame(width: 35, alignment: .center)
                    Text("GD")
                        .frame(width: 40, alignment: .center)
                    Text("PTS")
                        .frame(width: 45, alignment: .trailing)
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                
                // Standings Stream List Layout
                if isLoading {
                    Spacer()
                    ProgressView("Updating table standings...")
                        .tint(.green)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(leagueService.standings) { standing in
                                StandingsRow(standing: standing)
                                Divider()
                                    .padding(.leading, 45)
                            }
                        }
                    }
                }
            }
            .navigationTitle("League Table")
            .task {
                isLoading = true
                await leagueService.fetchTableData()
                isLoading = false
            }
        }
    }
}

// MARK: - Standings Row Component

struct StandingsRow: View {
    let standing: Standing
    
    var body: some View {
        HStack(spacing: 0) {
            // Position Label
            Text("\(standing.position)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .frame(width: 30, alignment: .leading)
                .foregroundColor(positionColor(for: standing.position))
            
            // Team Identity Grid
            HStack(spacing: 10) {
                TeamLogoView(teamName: standing.teamName)
                    .frame(width: 24, height: 24)
                
                Text(standing.teamName)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Matches Played
            Text("\(standing.played)")
                .font(.system(size: 14))
                .frame(width: 35, alignment: .center)
                .foregroundColor(.secondary)
            
            // Goal Difference
            Text("\(standing.goalDifference >= 0 ? "+" : "")\(standing.goalDifference)")
                .font(.system(size: 14, design: .rounded))
                .frame(width: 40, alignment: .center)
                .foregroundColor(standing.goalDifference >= 0 ? .primary : .red)
            
            // Points Column Total
            Text("\(standing.points)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .frame(width: 45, alignment: .trailing)
        }
        .padding(.horizontal)
        .frame(height: 48)
    }
    
    // Highlight top zone context styles natively
    private func positionColor(for pos: Int) -> Color {
        switch pos {
        case 1...4: return .blue       // Champions League zone illumination
        case 5: return .orange         // Europa League zone
        case 18...20: return .red      // Relegation drop zone
        default: return .primary
        }
    }
}
