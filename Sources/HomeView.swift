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
                // ✅ FIXED: Fallback parser strategy matches string formats directly instead of failing via ISO8601
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

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
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
                
                // 3. Compact Main Fixtures Feed Section
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
                    } else {
                        LazyVStack(spacing: 10) {
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
            .padding(.vertical, 12)
        }
        .navigationTitle("StrikeScore")
        .searchable(text: $searchText, prompt: "Search teams...")
        .sheet(item: $selectedMatch) { match in
            FeaturedMatchDetailView(match: match)
        }
        .refreshable {
            await viewModel.loadCMSData()
        }
    }
}
