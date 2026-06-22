import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    
    @State private var searchText = ""
    @State private var selectedDate = 0
    @State private var selectedMatch: FeaturedMatch? = nil
    @State private var selectedArticleFromSearch: EditorialItem? = nil
    
    private var targetFilteringDate: Date {
        Calendar.current.date(byAdding: .day, value: selectedDate, to: Date())!
    }

    var finishedMatches: [FeaturedMatch] {
        viewModel.featuredMatches.filter { $0.status.uppercased() == "FINISHED" }
    }

    var filteredMatches: [FeaturedMatch] {
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
                match.homeTeam.lowercased().contains(query) ||
                match.awayTeam.lowercased().contains(query) ||
                match.competition.lowercased().contains(query)
            }
            .sorted { $0.matchDate < $1.matchDate }
        }
    }

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
                // Search Bar Section
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
                        
                        // Swipeable Finished Matches Carousel (Swipe Right to Left)
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

                        // Date Selector System (Hidden during global text search)
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

                        if viewModel.isLoading {
                            ProgressView("Loading sports data...")
                                .padding(.top, 40)
                        } else {
                            if !searchText.isEmpty {
                                VStack(alignment: .leading, spacing: 20) {
                                    
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

// --- ADDED MISSING RECENT RESULTS CAROUSEL CARD ---
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
                        AsyncImage(url: match.homeFlagURL) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                Image(systemName: "sportscourt").resizable()
                            }
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
                        AsyncImage(url: match.awayFlagURL) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                Image(systemName: "sportscourt").resizable()
                            }
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

// --- ADDED MISSING FEATURED MATCH CARD STRUCT ---
struct FeaturedMatchCard: View {
    let featured: FeaturedMatch
    let isFavorited: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                HStack {
                    Spacer()
                    AsyncImage(url: featured.homeFlagURL) { phase in
                        if let image = phase.image { image.resizable().scaledToFill() }
                        else { Circle().fill(Color.gray.opacity(0.2)) }
                    }
                    .frame(width: 24, height: 24).clipShape(Circle())
                    
                    Text(featured.displayScore)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    
                    AsyncImage(url: featured.awayFlagURL) { phase in
                        if let image = phase.image { image.resizable().scaledToFill() }
                        else { Circle().fill(Color.gray.opacity(0.2)) }
                    }
                    .frame(width: 24, height: 24).clipShape(Circle())
                    Spacer()
                }
                
                HStack(spacing: 4) {
                    Text(featured.homeTeam).lineLimit(1)
                    Text("vs")
                        .foregroundColor(.secondary)
                        .font(.system(size: 10))
                    Text(featured.awayTeam).lineLimit(1)
                }
                .font(.system(size: 11, weight: .semibold))

                Text(featured.competition)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                if featured.isLive {
                    HStack(spacing: 2) {
                        Circle().fill(Color.red).frame(width: 6, height: 6)
                        Text("LIVE").font(.system(size: 8, weight: .bold)).foregroundColor(.red)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                Button(action: onFavorite) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 10))
                        .foregroundColor(isFavorited ? .red : .gray)
                        .padding(4)
                        .background(Color.black.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .padding(4),
                alignment: .topTrailing
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// --- ADDED MISSING DATE CELL STRUCT ---
struct DateCell: View {
    let day: Int
    let isSelected: Bool
    let action: () -> Void

    var dateLabel: String {
        let targetDate = Calendar.current.date(byAdding: .day, value: day, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        return formatter.string(from: targetDate)
    }

    var dayName: String {
        if day == 0 { return "Today" }
        let targetDate = Calendar.current.date(byAdding: .day, value: day, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: targetDate)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayName)
                    .font(.system(size: 10, weight: .bold))
                    .textCase(.uppercase)
                Text(dateLabel)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.green : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(10)
        }
    }
}
