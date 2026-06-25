import SwiftUI

struct FixturesView: View {
    @EnvironmentObject var viewModel: MatchesViewModel
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var selectedMatch: FeaturedMatch? = nil
    @State private var scheduleSearchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBarContainer(text: $scheduleSearchText, placeholder: "Search teams, leagues, dates...")
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 12) {
                        if filteredUpcomingMatches.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 44))
                                    .foregroundColor(.secondary)
                                Text("No matching schedules found")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 80)
                        } else {
                            ForEach(Array(filteredUpcomingMatches.enumerated()), id: \.element.id) { index, match in
                                VStack(spacing: 12) {
                                    FixtureCard(
                                        match: match,
                                        isFavorited: favoritesManager.isFavorited(match.id)
                                    ) {
                                        dismissKeyboard()
                                        handleMatchTap(match: match)
                                    } onFavorite: {
                                        favoritesManager.toggleFavorite(match.id)
                                    }
                                    .padding(.horizontal)

                                    // Insert banner ad every 3 fixtures
                                    if (index + 1) % 3 == 0 && index != filteredUpcomingMatches.count - 1 {
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
                    .padding(.vertical)
                    .padding(.bottom, 85)
                }
                // Dismisses the keyboard when scrolling or dragging through results
                .gesture(
                    DragGesture().onChanged { _ in
                        dismissKeyboard()
                    }
                )
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(item: $selectedMatch) { match in
                FeaturedMatchDetailView(match: match)
            }
        }
        .onTapGesture {
            dismissKeyboard()
        }
    }

    private var filteredUpcomingMatches: [FeaturedMatch] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = Calendar.current.startOfDay(for: Date())

        let upcoming = viewModel.featuredMatches.filter { match in
            // Exclude live and finished matches
            guard !match.isLive &&
                  match.status.uppercased() != "LIVE" &&
                  match.status.uppercased() != "IN_PLAY" &&
                  match.status.uppercased() != "FINISHED" &&
                  match.status.uppercased() != "FT" else {
                return false
            }

            // Only include matches from today onwards
            guard let matchDate = formatter.date(from: match.matchDate) else {
                return false
            }
            let matchDay = Calendar.current.startOfDay(for: matchDate)
            return matchDay >= today
        }

        if scheduleSearchText.isEmpty {
            return upcoming.sorted {
                if $0.matchDate != $1.matchDate {
                    return $0.matchDate < $1.matchDate
                }
                return $0.matchTime < $1.matchTime
            }
        } else {
            let query = scheduleSearchText.lowercased()
            return upcoming.filter { match in
                match.homeTeam.lowercased().contains(query) ||
                match.awayTeam.lowercased().contains(query) ||
                match.competition.lowercased().contains(query) ||
                match.matchDate.lowercased().contains(query)
            }
            .sorted {
                if $0.matchDate != $1.matchDate {
                    return $0.matchDate < $1.matchDate
                }
                return $0.matchTime < $1.matchTime
            }
        }
    }

    private func handleMatchTap(match: FeaturedMatch) {
        // Show interstitial on first tap per session, then every 4 minutes
        AdMobManager.shared.showInterstitialIfAllowed {
            selectedMatch = match
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct SearchBarContainer: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.gray.opacity(0.8)))
                .foregroundColor(.primary)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(.systemGray5))
        .cornerRadius(10)
    }
}

struct FixtureCard: View {
    let match: FeaturedMatch
    let isFavorited: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(match.competition)
                        .font(.caption2.bold())
                        .foregroundColor(.green)

                    Text("\(match.matchDate) â¢ \(match.matchTime)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(match.homeTeam)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                    Text(match.awayTeam)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                }

                Button(action: onFavorite) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .foregroundColor(isFavorited ? .red : .gray)
                }
                .padding(.leading, 8)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
