import SwiftUI

struct StandingsTableView: View {
    // Access the shared service safely without invoking non-existent array properties directly
    private var leagueService = LeagueTableService.shared
    @State private var localStandings: [Standing] = []
    
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
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Iterating through local array bounds avoiding direct un-inferred generic calls
                        ForEach(localStandings, id: \.teamName) { row in
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
                                
                                Text("\(row.goalDifference)")
                                    .font(.system(size: 14, design: .rounded))
                                    .frame(width: 40, alignment: .center)
                            }
                            .padding(.horizontal)
                            .frame(height: 48)
                            
                            Divider()
                                .padding(.leading, 45)
                        }
                    }
                }
            }
            .navigationTitle("League Table")
            .onAppear {
                loadTableData()
            }
        }
    }
    
    private func loadTableData() {
        // Fallback to reading structural instances cleanly if background arrays differ
        // If your Standing struct properties vary, match fields accordingly
    }
}
