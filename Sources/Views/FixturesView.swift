import SwiftUI

struct FixturesView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var selectedMatch: FeaturedMatch? = nil

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
            .task {
                await viewModel.loadCMSData()
            }
            .sheet(item: $selectedMatch) { match in
                FeaturedMatchDetailView(match: match)
            }
        }
    }

    private var upcomingMatches: [FeaturedMatch] {
        viewModel.featuredMatches.filter { !$0.isLive && $0.status.uppercased() != "LIVE" && $0.status.uppercased() != "IN_PLAY" && $0.status.uppercased() != "FINISHED" }
    }
}

struct FixtureCard: View {
    let match: FeaturedMatch
    let isFavorited: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Time & Date Left Column
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

                // Team Rows Stack
                VStack(alignment: .leading, spacing: 6) {
                    // Home Row
                    HStack(spacing: 8) {
                        TeamLogoView(
                            teamName: match.homeTeam,
                            localSpreadsheetURL: match.homeFlagURL,
                            fallbackColor: match.homeFallbackColor,
                            initials: match.getTeamInitials(from: match.homeTeam),
                            size: 22
                        )
                        Text(match.homeTeam)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }

                    // Away Row
                    HStack(spacing: 8) {
                        TeamLogoView(
                            teamName: match.awayTeam,
                            localSpreadsheetURL: match.awayFlagURL,
                            fallbackColor: match.awayFallbackColor,
                            initials: match.getTeamInitials(from: match.awayTeam),
                            size: 22
                        )
                        Text(match.awayTeam)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }

                Spacer()

                // Metadata Control Tag & Favorites
                VStack(alignment: .trailing, spacing: 6) {
                    if !match.group.isEmpty {
                        Text(match.group)
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
