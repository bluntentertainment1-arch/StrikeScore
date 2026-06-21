import SwiftUI

struct FixturesView: View {
    @StateObject private var viewModel = MatchesViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading && viewModel.upcomingMatches.isEmpty {
                        ProgressView("Loading fixtures...")
                            .padding()
                    } else if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    } else if viewModel.upcomingMatches.isEmpty {
                        Text("No upcoming fixtures")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(viewModel.upcomingMatches) { match in
                            FixtureCard(match: match)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Fixtures")
            .task {
                await viewModel.loadData()
            }
        }
    }
}

struct FixtureCard: View {
    let match: Match

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(match.displayDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(match.displayTime)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .frame(width: 80)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    AsyncImage(url: URL(string: match.homeTeam.crest ?? "")) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 24, height: 24)

                    Text(match.homeTeam.name)
                        .font(.subheadline)
                        .lineLimit(1)
                }

                HStack {
                    AsyncImage(url: URL(string: match.awayTeam.crest ?? "")) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 24, height: 24)

                    Text(match.awayTeam.name)
                        .font(.subheadline)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let group = match.group {
                Text(group.replacingOccurrences(of: "GROUP_", with: "Group "))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}
