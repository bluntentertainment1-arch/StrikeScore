import SwiftUI

struct StandingsTableView: View {
    @State private var standings: [TableTeamEntry] = []
    @State private var isLoading = true
    let leagueId: String = "4328" // Default Premier League ID
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Label Bar
                HStack(spacing: 0) {
                    Text("Pos").frame(width: 30, alignment: .leading)
                    Text("Team").frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 12) {
                        Text("PL").frame(width: 24, alignment: .center)
                        Text("GD").frame(width: 28, alignment: .center)
                        Text("PTS").frame(width: 32, alignment: .trailing)
                    }
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                
                if isLoading {
                    Spacer()
                    ProgressView("Updating table standings...")
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(standings) { team in
                                StandingsRow(team: team)
                                Divider().padding(.leading, 16)
                            }
                        }
                    }
                }
            }
            .navigationTitle("League Table")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                self.standings = await LeagueTableService.shared.fetchLeagueTable(leagueId: leagueId)
                self.isLoading = false
            }
        }
    }
}

struct StandingsRow: View {
    let team: TableTeamEntry
    
    var body: some View {
        HStack(spacing: 0) {
            // Position Rank
            Text(team.intRank)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .frame(width: 30, alignment: .leading)
                .foregroundColor(Int(team.intRank) ?? 0 <= 4 ? .green : .primary)
            
            // Crest and Label
            HStack(spacing: 8) {
                TeamLogoView(
                    teamName: team.strTeam,
                    localSpreadsheetURL: URL(string: team.strTeamBadge ?? ""),
                    fallbackColor: .gray,
                    initials: String(team.strTeam.prefix(2)),
                    size: 20
                )
                
                Text(team.strTeam)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Statistics Block
            HStack(spacing: 12) {
                Text(team.intPlayed)
                    .frame(width: 24, alignment: .center)
                
                Text(Int(team.intGoalDifference) ?? 0 > 0 ? "+\(team.intGoalDifference)" : team.intGoalDifference)
                    .frame(width: 28, alignment: .center)
                    .foregroundColor(Int(team.intGoalDifference) ?? 0 >= 0 ? .primary : .red)
                
                Text(team.intPoints)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .frame(width: 32, alignment: .trailing)
            }
            .font(.system(size: 13))
            .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
