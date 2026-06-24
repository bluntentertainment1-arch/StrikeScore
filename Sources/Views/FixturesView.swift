import SwiftUI

struct FixturesView: View {
    // Uses the standard shared view-model pattern tracking the main API data array
    @ObservedObject var viewModel = MatchesViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var selectedMatch: Match? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if upcomingMatches.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "calendar")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No upcoming fixtures")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 100)
                    } else {
                        ForEach(upcomingMatches) { match in
                            FixtureCard(
                                match: match,
                                isFavorited: favoritesManager.isFavorited(match.id)
                            ) {
                                selectedMatch = match
                            } onFavorite: {
                                favoritesManager.toggleFavorite(match.id)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedMatch) { match in
                // Updated component context to accept the updated API Match type structure
                FeaturedMatchDetailView(match: match)
            }
        }
    }

    private var upcomingMatches: [Match] {
        // Safely screens out completed or active fixtures from the target match list
        viewModel.allMatches.filter { !$0.isLive && !$0.isFinished && $0.status.uppercased() != "IN_PLAY" }
    }
}

struct FixtureCard: View {
    let match: Match
    let isFavorited: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Time & Date Column (Reads cleanly from Match computed helpers)
                VStack(alignment: .leading, spacing: 3) {
                    Text(match.displayDate)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Text(match.displayTime)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                }
                .frame(width: 75, alignment: .leading)

                // Teams Stack Layout
                VStack(alignment: .leading, spacing: 6) {
                    // Home Team Row
                    HStack(spacing: 8) {
                        TeamLogoView(teamName: match.homeTeam.name, size: 22)
                        Text(match.homeTeam.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }

                    // Away Team Row
                    HStack(spacing: 8) {
                        TeamLogoView(teamName: match.awayTeam.name, size: 22)
                        Text(match.awayTeam.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }

                Spacer()

                // Group Tags & Favorites Button
                VStack(alignment: .trailing, spacing: 6) {
                    if let groupName = match.group, !groupName.isEmpty {
                        Text(groupName)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(6)
                    }

                    Button(action: onFavorite) {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .font(.system(size: 15))
                            .foregroundColor(isFavorited ? .red : .gray.opacity(0.7))
                            .padding(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
