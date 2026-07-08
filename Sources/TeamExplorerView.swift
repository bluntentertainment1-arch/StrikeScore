import SwiftUI

struct TeamExplorerView: View {
    @EnvironmentObject var viewModel: MatchesViewModel
    @State private var searchText = ""
    @State private var selectedTeam: String? = nil
    @State private var showTeamMatches = false

    private var allTeams: [String] {
        let teams = Set(viewModel.featuredMatches.flatMap { [$0.homeTeam, $0.awayTeam] })
        return teams.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var filteredTeams: [String] {
        if searchText.isEmpty { return allTeams }
        return allTeams.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    private var selectedTeamMatches: [FeaturedMatch] {
        guard let team = selectedTeam else { return [] }
        return viewModel.featuredMatches.filter {
            $0.homeTeam == team || $0.awayTeam == team
        }.sorted {
            if $0.matchDate != $1.matchDate { return $0.matchDate < $1.matchDate }
            return $0.matchTime < $1.matchTime
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search teams...", text: $searchText)
                            .foregroundColor(.primary)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray5))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    if filteredTeams.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "shield.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("No teams found")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 100)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredTeams, id: \.self) { team in
                                Button(action: {
                                    selectedTeam = team
                                    showTeamMatches = true
                                }) {
                                    HStack(spacing: 16) {
                                        // Team initials badge
                                        ZStack {
                                            Circle()
                                                .fill(teamColor(for: team))
                                                .frame(width: 40, height: 40)
                                            Text(teamInitials(for: team))
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(team)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.primary)
                                            Text("\(teamMatchCount(team)) matches")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemBackground))
                                }
                                .buttonStyle(PlainButtonStyle())

                                Divider()
                                    .padding(.leading, 72)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Teams")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(isPresented: $showTeamMatches) {
                if let team = selectedTeam {
                    TeamMatchesView(team: team, matches: selectedTeamMatches)
                }
            }
        }
    }

    private func teamMatchCount(_ team: String) -> Int {
        viewModel.featuredMatches.filter { $0.homeTeam == team || $0.awayTeam == team }.count
    }

    private func teamColor(for team: String) -> Color {
        let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .teal, .indigo, .cyan, .yellow]
        let sum = team.utf8.reduce(0) { $0 + Int($1) }
        return colors[sum % colors.count]
    }

    private func teamInitials(for team: String) -> String {
        let clean = team.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = clean.components(separatedBy: " ")
        if words.count >= 2 {
            return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
        }
        return String(clean.prefix(2)).uppercased()
    }
}

struct TeamMatchesView: View {
    let team: String
    let matches: [FeaturedMatch]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMatch: FeaturedMatch? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Team header
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(teamColor(for: team))
                            .frame(width: 60, height: 60)
                        Text(teamInitials(for: team))
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(team)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("\(matches.count) matches")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Matches grouped by competition
                let grouped = Dictionary(grouping: matches) { $0.competition }
                ForEach(grouped.keys.sorted(), id: \.self) { competition in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "shield.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.green)
                            Text(competition.uppercased())
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(.green)
                                .tracking(0.5)
                            Rectangle()
                                .fill(Color.green.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal)

                        VStack(spacing: 10) {
                            ForEach(grouped[competition]!) { match in
                                MatchCardView(match: match, onTap: {
                                    selectedMatch = match
                                })
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(team)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedMatch) { match in
            FeaturedMatchDetailView(match: match)
        }
    }

    private func teamColor(for team: String) -> Color {
        let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .teal, .indigo, .cyan, .yellow]
        let sum = team.utf8.reduce(0) { $0 + Int($1) }
        return colors[sum % colors.count]
    }

    private func teamInitials(for team: String) -> String {
        let clean = team.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = clean.components(separatedBy: " ")
        if words.count >= 2 {
            return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
        }
        return String(clean.prefix(2)).uppercased()
    }
}
