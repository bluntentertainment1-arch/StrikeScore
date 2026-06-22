import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    
    @State private var searchText = ""
    @State private var selectedDate = 0
    @State private var selectedMatch: FeaturedMatch? = nil
    @State private var selectedArticleFromSearch: EditorialItem? = nil
    @State private var glowAnimation = false
    
    private var targetFilteringDate: Date {
        Calendar.current.date(byAdding: .day, value: selectedDate, to: Date())!
    }

    var finishedMatches: [FeaturedMatch] {
        viewModel.featuredMatches.filter { 
            $0.status.uppercased() == "FINISHED" || 
            (!$0.homeScore.isEmpty && !$0.awayScore.isEmpty && !$0.isLive && $0.status.uppercased() != "TIMED")
        }
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
                        
                        // Swipeable Finished Matches Carousel
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

                        // Date Selector System
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
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(match.isLive ? Color.red : Color.clear, lineWidth: match.isLive ? 1.5 : 0)
                                                        .shadow(color: match.isLive ? Color.red.opacity(glowAnimation ? 0.8 : 0.2) : Color.clear, radius: glowAnimation ? 5 : 2)
                                                )
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
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(match.isLive ? Color.red : Color.clear, lineWidth: match.isLive ? 1.5 : 0)
                                                    .shadow(color: match.isLive ? Color.red.opacity(glowAnimation ? 0.8 : 0.2) : Color.clear, radius: glowAnimation ? 5 : 2)
                                            )
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
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    glowAnimation = true
                }
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

// --- VERTI-CONTAINER CAROUSEL CARD INTEGRATING ADVANCED LOGO DETECTOR ---
struct FinishedMatchCarouselCard: View {
    let match: FeaturedMatch
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Text(match.competition)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 0) {
                    // Home Side
                    VStack(spacing: 8) {
                        TeamLogoView(
                            teamName: match.homeTeam,
                            localSpreadsheetURL: match.homeFlagURL,
                            fallbackColor: match.homeFallbackColor,
                            initials: match.getTeamInitials(from: match.homeTeam),
                            size: 28
                        )
                        
                        Text(match.homeTeam)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 32)
                        .padding(.horizontal, 4)
                    
                    // Away Side
                    VStack(spacing: 8) {
                        TeamLogoView(
                            teamName: match.awayTeam,
                            localSpreadsheetURL: match.awayFlagURL,
                            fallbackColor: match.awayFallbackColor,
                            initials: match.getTeamInitials(from: match.awayTeam),
                            size: 28
                        )
                        
                        Text(match.awayTeam)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Text(!match.homeScore.isEmpty && !match.awayScore.isEmpty ? "\(match.homeScore) - \(match.awayScore)" : "FINAL FT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .frame(width: 155, height: 135)
            .background(Color(.systemGray5).opacity(0.6))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// --- GRID FEAT CARD INTEGRATING ADVANCED LOGO DETECTOR ---
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
                    TeamLogoView(
                        teamName: featured.homeTeam,
                        localSpreadsheetURL: featured.homeFlagURL,
                        fallbackColor: featured.homeFallbackColor,
                        initials: featured.getTeamInitials(from: featured.homeTeam),
                        size: 24
                    )
                    
                    Text(featured.displayScore)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(featured.isLive ? .red : .primary)
                    
                    TeamLogoView(
                        teamName: featured.awayTeam,
                        localSpreadsheetURL: featured.awayFlagURL,
                        fallbackColor: featured.awayFallbackColor,
                        initials: featured.getTeamInitials(from: featured.awayTeam),
                        size: 24
                    )
                    Spacer()
                }
                
                HStack(spacing: 4) {
                    Text(featured.homeTeam).lineLimit(1)
                    Text("vs").foregroundColor(.secondary).font(.system(size: 10))
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

struct DateCell: View {
    let day: Int
    let isSelected: Bool
    let action: () -> Void

    var dateLabel: String {
        let targetDate = Calendar.current.date(byAdding: .day, value: day, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: targetDate)
    }

    var dayName: String {
        if day == 0 { return "TODAY" }
        let targetDate = Calendar.current.date(byAdding: .day, value: day, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: targetDate).uppercased()
    }
    
    var monthName: String {
        let targetDate = Calendar.current.date(byAdding: .day, value: day, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: targetDate)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(dayName)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.5)
                Text("\(dateLabel) \(monthName)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(minWidth: 76)
            .background(isSelected ? Color.green : Color.clear)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
