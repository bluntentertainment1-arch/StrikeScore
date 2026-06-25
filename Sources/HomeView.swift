import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: MatchesViewModel
    @StateObject private var favoritesManager = FavoritesManager.shared

    @State private var searchText = ""
    @State private var selectedDate = 0
    @State private var selectedMatch: FeaturedMatch? = nil

    private var targetFilteringDate: Date {
        Calendar.current.date(byAdding: .day, value: selectedDate, to: Date())!
    }

    var finishedResultsMatches: [FeaturedMatch] {
        viewModel.featuredMatches.filter { 
            $0.status.uppercased() == "FINISHED" || $0.status.uppercased() == "FT" 
        }
    }

    var filteredFixturesFeed: [FeaturedMatch] {
        if searchText.isEmpty {
            return viewModel.featuredMatches.filter { match in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                guard let matchDateObj = formatter.date(from: match.matchDate) else { return false }
                return Calendar.current.isDate(matchDateObj, inSameDayAs: targetFilteringDate)
            }
            .sorted { $0.matchTime < $1.matchTime }
        } else {
            let query = searchText.lowercased()
            return viewModel.featuredMatches.filter { match in
                match.homeTeam.lowercased().contains(query) || match.awayTeam.lowercased().contains(query)
            }
        }
    }

    // Group fixtures by competition for the non-search view
    var groupedFixtures: [(competition: String, matches: [FeaturedMatch])] {
        let fixtures = filteredFixturesFeed
        let grouped = Dictionary(grouping: fixtures) { $0.competition }
        return grouped
            .sorted { $0.value.count > $1.value.count } // Sort by most matches first
            .map { (competition: $0.key, matches: $0.value.sorted { $0.matchTime < $1.matchTime }) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Banner Ad right below menu bar, above date picker
                    InlineBannerAdView(
                        adUnitID: AdMobManager.bannerAdUnitID,
                        adSize: .standard
                    )
                    .padding(.horizontal)
                    .padding(.top, 4)

                    // 1. Horizontal Date Picker Slider
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(-3...7, id: \.self) { day in
                                DateBubbleView(day: day, isSelected: selectedDate == day) {
                                    selectedDate = day
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // 2. Latest Results Carousel
                    if !finishedResultsMatches.isEmpty && searchText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.orange)
                                Text("LATEST RESULTS")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.secondary)
                                    .tracking(0.5)
                            }
                            .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(finishedResultsMatches) { match in
                                        Button(action: { selectedMatch = match }) {
                                            HomeResultsCarouselCard(match: match)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 2)
                            }
                        }
                    }

                    // 3. Compact Main Fixtures Feed Section - Grouped by Competition
                    VStack(alignment: .leading, spacing: 10) {
                        Text(searchText.isEmpty ? "Fixtures Feed" : "Search Results")
                            .font(.system(size: 16, weight: .bold))
                            .padding(.horizontal)

                        if filteredFixturesFeed.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "sportscourt")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                Text("No fixtures scheduled for this day")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                        } else if searchText.isEmpty {
                            // Grouped by competition when not searching
                            LazyVStack(spacing: 16) {
                                ForEach(Array(groupedFixtures.enumerated()), id: \.offset) { groupIndex, group in
                                    VStack(alignment: .leading, spacing: 10) {
                                        // Competition Header
                                        HStack(spacing: 6) {
                                            Image(systemName: "shield.fill")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.green)
                                            Text(group.competition.uppercased())
                                                .font(.system(size: 12, weight: .black))
                                                .foregroundColor(.green)
                                                .tracking(0.5)

                                            Rectangle()
                                                .fill(Color.green.opacity(0.3))
                                                .frame(height: 1)
                                        }
                                        .padding(.horizontal)

                                        // Matches in this competition
                                        VStack(spacing: 10) {
                                            ForEach(Array(group.matches.enumerated()), id: \.element.id) { matchIndex, match in
                                                VStack(spacing: 10) {
                                                    MatchCardView(match: match, onTap: {
                                                        selectedMatch = match
                                                    })
                                                    .padding(.horizontal)

                                                    // Insert banner ad every 3 fixtures globally
                                                    let globalIndex = groupIndex * 100 + matchIndex // rough global index
                                                    if (globalIndex + 1) % 3 == 0 {
                                                        InlineBannerAdView(
                                                            adUnitID: AdMobManager.bannerAdUnitID,
                                                            adSize: .standard
                                                        )
                                                        .padding(.horizontal)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            // Flat list when searching
                            LazyVStack(spacing: 10) {
                                ForEach(Array(filteredFixturesFeed.enumerated()), id: \.element.id) { index, match in
                                    VStack(spacing: 10) {
                                        MatchCardView(match: match, onTap: {
                                            selectedMatch = match
                                        })
                                        .padding(.horizontal)

                                        if (index + 1) % 3 == 0 && index != filteredFixturesFeed.count - 1 {
                                            InlineBannerAdView(
                                                adUnitID: AdMobManager.bannerAdUnitID,
                                                adSize: .standard
                                            )
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 12)
            }
            .navigationTitle("StrikeScore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .padding(.top, 44)
            .searchable(text: $searchText, prompt: "Search teams...")
            .sheet(item: $selectedMatch) { match in
                FeaturedMatchDetailView(match: match)
            }
            .refreshable {
                await viewModel.loadCMSData()
            }
        }
    }
}

struct HomeResultsCarouselCard: View {
    let match: FeaturedMatch

    var body: some View {
        VStack(spacing: 8) {
            Text(match.competition.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
                .lineLimit(1)

            HStack(spacing: 6) {
                VStack(spacing: 4) {
                    TeamLogoView(
                        teamName: match.homeTeam,
                        localSpreadsheetURL: match.homeFlagURL,
                        fallbackColor: match.homeFallbackColor,
                        initials: match.getTeamInitials(from: match.homeTeam),
                        size: 26
                    )
                    Text(match.homeTeam)
                        .font(.system(size: 11, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(width: 75)

                VStack(spacing: 2) {
                    Text(match.displayScore)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                    Text("FT")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.secondary)
                }
                .frame(width: 50)

                VStack(spacing: 4) {
                    TeamLogoView(
                        teamName: match.awayTeam,
                        localSpreadsheetURL: match.awayFlagURL,
                        fallbackColor: match.awayFallbackColor,
                        initials: match.getTeamInitials(from: match.awayTeam),
                        size: 26
                    )
                    Text(match.awayTeam)
                        .font(.system(size: 11, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(width: 75)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

struct DateBubbleView: View {
    let day: Int
    let isSelected: Bool
    let onTap: () -> Void

    private var calculatedDate: Date {
        Calendar.current.date(byAdding: .day, value: day, to: Date()) ?? Date()
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(calculatedDate.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(isSelected ? .white : .secondary)

                Text(calculatedDate.formatted(.dateTime.day()))
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 44, height: 52)
            .background(isSelected ? Color.green : Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
