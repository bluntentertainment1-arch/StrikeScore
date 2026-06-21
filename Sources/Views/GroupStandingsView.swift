import SwiftUI

struct GroupStandingsView: View {
    @StateObject private var viewModel = MatchesViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading && viewModel.standings.isEmpty {
                        ProgressView("Loading standings...")
                            .padding()
                    } else if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        ForEach(viewModel.standings) { standing in
                            GroupStandingCard(standing: standing)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Standings")
            .task {
                await viewModel.loadData()
            }
        }
    }
}

struct GroupStandingCard: View {
    let standing: GroupStanding

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(standing.displayGroup)
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            Divider()
                .padding(.horizontal, 16)

            HStack(spacing: 12) {
                Text("")
                    .frame(width: 24)
                Text("")
                    .frame(width: 24)
                Text("Team")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 8) {
                    Text("P").frame(width: 24)
                    Text("W").frame(width: 24)
                    Text("D").frame(width: 24)
                    Text("L").frame(width: 24)
                    Text("GD").frame(width: 32)
                    Text("Pts").frame(width: 32)
                }
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)

            ForEach(standing.table) { team in
                TeamStandingRow(team: team)
                    .padding(.horizontal, 16)
            }
            .padding(.bottom, 12)
        }
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct TeamStandingRow: View {
    let team: TeamStanding

    var qualificationColor: Color {
        if team.isQualified { return .green }
        if team.isPossible { return .yellow }
        return .clear
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("\(team.position)")
                .font(.system(size: 14, weight: .bold))
                .frame(width: 24)

            AsyncImage(url: URL(string: team.team.crest ?? "")) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.3))
            }
            .frame(width: 24, height: 24)

            Text(team.team.name)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)

            Spacer()

            HStack(spacing: 8) {
                Text("\(team.playedGames)").frame(width: 24)
                Text("\(team.won)").frame(width: 24)
                Text("\(team.draw)").frame(width: 24)
                Text("\(team.lost)").frame(width: 24)
                Text("\(team.goalDifference)").frame(width: 32)
                Text("\(team.points)")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 32)
            }
            .font(.system(size: 12))
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .background(qualificationColor.opacity(0.1))
        .cornerRadius(4)
    }
}
