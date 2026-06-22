import SwiftUI

struct StandingsTableView: View {
    private let leagueService = LeagueTableService.shared
    @State private var tableEntries: [TableTeamEntry] = []
    @State private var leagueId: String = "4328"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("#")
                        .frame(width: 30, alignment: .leading)
                    Text("Team")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("P")
                        .frame(width: 35, alignment: .center)
                    Text("GD")
                        .frame(width: 40, alignment: .center)
                    Text("Pts")
                        .frame(width: 40, alignment: .center)
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(0..<tableEntries.count, id: \.self) { index in
                            let entry = tableEntries[index]
                            HStack(spacing: 0) {
                                Text(entry.intRank)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .frame(width: 30, alignment: .leading)

                                HStack(spacing: 10) {
                                    TeamLogoView(teamName: entry.strTeam)
                                        .frame(width: 24, height: 24)
                                    Text(entry.strTeam)
                                        .font(.system(size: 14, weight: .medium))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Text(entry.intPlayed)
                                    .font(.system(size: 14))
                                    .frame(width: 35, alignment: .center)
                                    .foregroundColor(.secondary)

                                Text(entry.intGoalDifference)
                                    .font(.system(size: 14, design: .rounded))
                                    .frame(width: 40, alignment: .center)

                                Text(entry.intPoints)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
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
            .task {
                await loadTableData()
            }
        }
    }

    private func loadTableData() async {
        tableEntries = await leagueService.fetchLeagueTable(leagueId: leagueId)
    }
}
