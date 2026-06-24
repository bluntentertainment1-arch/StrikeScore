import SwiftUI

struct FixturesView: View {
    // ✅ FIXED: Now reads from shared EnvironmentObject layout engine
    @EnvironmentObject var viewModel: MatchesViewModel
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var selectedMatch: FeaturedMatch? = nil

    // Filters strictly for "SCHEDULED" entries and groups them cleanly by Competition
    private var groupedFixtures: [(competition: String, matches: [FeaturedMatch])] {
        let scheduledMatches = viewModel.featuredMatches.filter { match in
            match.status.uppercased() == "SCHEDULED"
        }
        let dictionary = Dictionary(grouping: scheduledMatches, by: { $0.competition })
        return dictionary.map { (competition: $0.key, matches: $0.value) }
            .sorted { $0.competition < $1.competition }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if groupedFixtures.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "calendar")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No upcoming scheduled fixtures")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 100)
                    } else {
                        LazyVStack(alignment: .leading, spacing: 14, pinnedViews: [.sectionHeaders]) {
                            ForEach(groupedFixtures, id: \.competition) { section in
                                Section(header: sectionHeaderView(section.competition)) {
                                    ForEach(section.matches) { match in
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
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            // Note: Data loading task has been removed since app-level orchestration covers preloading
            .sheet(item: $selectedMatch) { match in
                FeaturedMatchDetailView(match: match)
            }
        }
    }

    private func sectionHeaderView(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .black))
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGroupedBackground))
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
                // Time & Status Column
                VStack(alignment: .center, spacing: 4) {
                    Text(match.matchTime)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text(match.matchDate)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(width: 65)

                Divider()
                    .frame(height: 35)

                // Teams Presentation Column
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        TeamLogoView(
                            teamName: match.homeTeam,
                            localSpreadsheetURL: match.homeFlagURL,
                            fallbackColor: match.homeFallbackColor,
                            initials: match.getTeamInitials(from: match.homeTeam),
                            size: 18
                        )
                        Text(match.homeTeam)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }

                    HStack(spacing: 8) {
                        TeamLogoView(
                            teamName: match.awayTeam,
                            localSpreadsheetURL: match.awayFlagURL,
                            fallbackColor: match.awayFallbackColor,
                            initials: match.getTeamInitials(from: match.awayTeam),
                            size: 18
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
