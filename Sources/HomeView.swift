import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    
    @State private var searchText = ""
    @State private var selectedDate = 0
    @State private var selectedMatch: FeaturedMatch? = nil
    
    private var targetFilteringDate: Date {
        Calendar.current.date(byAdding: .day, value: selectedDate, to: Date())!
            .addingTimeInterval(TimeInterval(Calendar.current.timeZone.secondsFromGMT()))
    }

    // Filter only ongoing active live matches for the prominent top carousel
    var activeLiveMatches: [FeaturedMatch] {
        viewModel.featuredMatches.filter { $0.isCurrentlyLive }
    }

    // Filter standard scheduled fixtures matching the selected date bubble
    var filteredFixturesFeed: [FeaturedMatch] {
        if searchText.isEmpty {
            return viewModel.featuredMatches.filter { match in
                let formatter = ISO8601DateFormatter()
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    
                    // 1. Horizontal Date Picker Carousel
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(-3...7, id: \.self) { day in
                                DateBubbleView(day: day, isSelected: selectedDate == day) {
                                    selectedDate = day
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 2. Prominent Horizontal Live Slider (Only shows if live matches are running)
                    if !activeLiveMatches.isEmpty && searchText.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                Text("LIVE MATCHES")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(activeLiveMatches) { match in
                                        Button(action: { selectedMatch = match }) {
                                            HomeLiveCarouselCard(match: match)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 4)
                            }
                        }
                    }
                    
                    // 3. Clean Main Fixtures Feed Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(searchText.isEmpty ? "Fixtures Feed" : "Search Results")
                            .font(.system(size: 18, weight: .bold))
                            .padding(.horizontal)
                        
                        if filteredFixturesFeed.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "sportscourt")
                                    .font(.title)
                                    .foregroundColor(.secondary)
                                Text("No fixtures scheduled for this day")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredFixturesFeed) { match in
                                    MatchCardView(match: match, onTap: {
                                        selectedMatch = match
                                    })
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("StrikeScore")
            .searchable(text: $searchText, prompt: "Search teams...")
            .sheet(item: $selectedMatch) { match in
                FeaturedMatchDetailView(match: match)
            }
            .task {
                await viewModel.loadCMSData()
            }
        }
    }
}

// MARK: - Premium Horizontal Live Card for Home Layout
struct HomeLiveCarouselCard: View {
    let match: FeaturedMatch
    
    var body: some View {
        VStack(spacing: 12) {
            Text(match.competition.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            HStack(spacing: 16) {
                // Home Team Focus
                VStack(spacing: 6) {
                    TeamLogoView(
                        teamName: match.homeTeam,
                        localSpreadsheetURL: match.homeFlagURL,
                        fallbackColor: match.homeFallbackColor,
                        initials: match.getTeamInitials(from: match.homeTeam),
                        size: 34
                    )
                    Text(match.homeTeam)
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                }
                .frame(width: 80)
                
                // Score Center
                VStack(spacing: 2) {
                    Text(match.displayScore)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.green)
                    Text(match.status)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.red)
                }
                
                // Away Team Focus
                VStack(spacing: 6) {
                    TeamLogoView(
                        teamName: match.awayTeam,
                        localSpreadsheetURL: match.awayFlagURL,
                        fallbackColor: match.awayFallbackColor,
                        initials: match.getTeamInitials(from: match.awayTeam),
                        size: 34
                    )
                    Text(match.awayTeam)
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                }
                .frame(width: 80)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
    }
}
