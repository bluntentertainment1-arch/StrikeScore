import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    
    @State private var searchText = ""
    @State private var selectedDate = 0
    @State private var selectedMatch: FeaturedMatch? = nil
    @State private var selectedArticleFromSearch: EditorialItem? = nil
    
    // Target date matching calculations for standard unfiltered views
    private var targetFilteringDate: Date {
        Calendar.current.date(byAdding: .day, value: selectedDate, to: Date())!
    }

    // --- SWIPE CAROUSEL ENGINE: FINISHED MATCHES ---
    var finishedMatches: [FeaturedMatch] {
        viewModel.featuredMatches.filter { $0.status.uppercased() == "FINISHED" }
    }

    // --- WORKING GLOBAL SEARCH ENGINE (BYPASSES DATES IF QUERY ACTIVE) ---
    var filteredMatches: [FeaturedMatch] {
        if searchText.isEmpty {
            // Standard Flow: Filter strictly by selected day cell
            return viewModel.featuredMatches.filter { match in
                let formatter = ISO8601DateFormatter()
                guard let matchDateObj = formatter.date(from: match.matchDate) else { return false }
                return Calendar.current.isDate(matchDateObj, inSameDayAs: targetFilteringDate)
            }
            .sorted { $0.matchTime < $1.matchTime }
        } else {
            // Global Search Flow: Ignore date cells, scan entire array
            let query = searchText.lowercased()
            return viewModel.featuredMatches.filter { match in
                match.homeTeam.lowercased().contains(query) ||
                match.awayTeam.lowercased().contains(query) ||
                match.competition.lowercased().contains(query)
            }
            .sorted { $0.matchDate < $1.matchDate } // Chronological by date order
        }
    }

    // --- GLOBAL NEWS SEARCH ENGINE ---
    var filteredNews: [EditorialItem] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        return viewModel.editorialItems.filter { item in
            item.headline.lowercased().contains(query) ||
            item.body.lowercased().contains(query) ||
            item.fullContent.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Field Layout
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search teams, matches, or news...", text: $searchText)
                        .foregroundColor(.primary)
                        .autocorrectionDisabled()
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 16) {
                        
                        // 1. SWIPE FROM RIGHT TO LEFT CAROUSEL (FINISHED MATCHES)
                        // Placed exactly between search bar and date section
                        if searchText.isEmpty && !finishedMatches.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Recent Results")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(finishedMatches) { match in
                                            FinishedMatchCarouselCard(match: match) {
                                                selectedMatch = match
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }

                        // 2. DATE SELECTOR SYSTEM (Hidden when searching globally)
                        if searchText.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(0..<7) { day in
                                        DateCell(day: day, isSelected: day == selectedDate) {
                                            selectedDate = day
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        // 3. MAIN DISPLAY ROUTER
                        if viewModel.isLoading {
                            ProgressView("Loading sports data...")
                                .padding(.top, 40)
                        } else {
                            // Render Global Search Block if Query string is active
                            if !searchText.isEmpty {
                                VStack(alignment: .leading, spacing: 20) {
                                    
                                    // Matched Fixtures Block
                                    Text("Matches (\(filteredMatches.count))")
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    if filteredMatches.isEmpty {
                                        Text("No matches found matching \"\(searchText)\"")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal)
                                    } else {
                                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                            ForEach(filteredMatches) { match in
                                                FeaturedMatchCard(featured: match, isFavorited: favoritesManager.isFavorited(match.id)) {
                                                    selectedMatch = match
                                                } onFavorite: {
                                                    favoritesManager.toggleFavorite(match.id)
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                    
                                    Divider().padding(.horizontal)
                                    
                                    // Matched News Block
                                    Text("News Articles (\(filteredNews.count))")
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    if filteredNews.isEmpty {
                                        Text("No news updates found matching \"\(searchText)\"")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal)
                                    } else {
                                        ForEach(filteredNews) { article in
                                            Button(action: { selectedArticleFromSearch = article }) {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    Text(article.headline)
                                                        .font(.subheadline)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.primary)
                                                        .multilineTextAlignment(.leading)
                                                    Text(article.body)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(2)
                                                        .multilineTextAlignment(.leading)
                                                }
                                                .padding()
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .background(Color(.systemGray6))
                                                .cornerRadius(12)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                            } else {
                                // Default Static Dashboard View
                                if filteredMatches.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "sportscourt")
                                            .font(.largeTitle)
                                            .foregroundColor(.secondary)
                                        Text("No matches scheduled for this day")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.top, 40)
                                } else {
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                        ForEach(filteredMatches) { match in
                                            FeaturedMatchCard(featured: match, isFavorited: favoritesManager.isFavorited(match.id)) {
                                                selectedMatch = match
                                            } onFavorite: {
                                                favoritesManager.toggleFavorite(match.id)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
                // FIXED: Dismiss keyboard cleanly when user drags or taps outside field area
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
            .navigationTitle("StrikeScore")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadCMSData()
            }
            .sheet(item: $selectedMatch) { match in
                FeaturedMatchDetailView(match: match)
            }
            .sheet(item: $selectedArticleFromSearch) { article in
                ArticleDetailView(article: article, allArticles: viewModel.editorialItems)
            }
        }
    }
}

// --- VISUAL IMPROVEMENT COMPONENT: SWIPEABLE RESULTS CARD ---
struct FinishedMatchCarouselCard: View {
    let match: FeaturedMatch
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(match.competition)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Spacer()
                    VStack(spacing: 4) {
                        AsyncImage(url: match.homeFlagURL) { p in
                            p.image?.resizable().scaledToFill() ?? Image(systemName: "sportscourt").resizable()
                        }
                        .frame(width: 20, height: 20).clipShape(Circle())
                        Text(match.homeTeam).font(.caption2).fontWeight(.semibold).lineLimit(1)
                    }
                    .frame(width: 55)
                    
                    Text("\(match.homeScore) - \(match.awayScore)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(6)
                    
                    VStack(spacing: 4) {
                        AsyncImage(url: match.awayFlagURL) { p in
                            p.image?.resizable().scaledToFill() ?? Image(systemName: "sportscourt").resizable()
                        }
                        .frame(width: 20, height: 20).clipShape(Circle())
                        Text(match.awayTeam).font(.caption2).fontWeight(.semibold).lineLimit(1)
                    }
                    .frame(width: 55)
                    Spacer()
                }
                
                Text("FINAL FT")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .frame(width: 175)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
