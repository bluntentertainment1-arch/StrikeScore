import SwiftUI

struct StandingsTableView: View {
    // Fixed: Accessed via singleton pattern to satisfy private protection levels
    @ObservedObject private var leagueService = LeagueTableService.shared
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
                
                if isLoading {
                    Spacer()
                    ProgressView("Updating table standings...")
                        .tint(.green)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // Fixed: Using your codebase's matching model structure parameters
                            ForEach(leagueService.tableRows) { row in
                                HStack(spacing: 0) {
                                    Text("\(row.position)")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .frame(width: 30, alignment: .leading)
                                    
                                    HStack(spacing: 10) {
                                        TeamLogoView(teamName: row.teamName)
                                            .frame(width: 24, height: 24)
                                        Text(row.teamName)
                                            .font(.system(size: 14, weight: .medium))
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Text("\(row.played)")
                                        .font(.system(size: 14))
                                        .frame(width: 35, alignment: .center)
                                        .foregroundColor(.secondary)
                                    
                                    Text("\(row.goalDifference >= 0 ? "+" : "")\(row.goalDifference)")
                                        .font(.system(size: 14, design: .rounded))
                                        .frame(width: 40, alignment: .center)
                                    
                                    Text("\(row.points)")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .frame(width: 45, alignment: .trailing)
                                }
                                .padding(.horizontal)
                                .frame(height: 48)
                                
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
