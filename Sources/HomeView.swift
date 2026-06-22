import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    
    @State private var searchText = ""
    @State private var selectedDate = 0
    @State private var selectedMatch: FeaturedMatch? = nil
    
    private var targetFilteringDate: Date {
        Calendar.current.date(byAdding: .day, value: selectedDate, to: Date())!
    }

    var activeLiveMatches: [FeaturedMatch] {
        viewModel.featuredMatches.filter { $0.isCurrentlyLive }
    }

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
                    
                    // 2. Optimized Live Slider Horizontal Row
                    if !activeLiveMatches.isEmpty && searchText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                Text("LIVE MATCHES")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.red)
                                    .tracking(0.5)
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(activeLiveMatches) { match in
                                        Button(action: { selectedMatch = match }) {
                                            HomeLiveCarouselCard(match: match)
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
            .task {
                await viewModel.loadCMSData()
            }
        }
    }
}

struct DateBubbleView: View {
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
            VStack(spacing: 2) {
                Text(dayName)
                    .font(.system(size: 8, weight: .bold))
                Text("\(dateLabel) \(monthName)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .frame(minWidth: 70)
            .background(isSelected ? Color.green : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HomeLiveCarouselCard: View {
    let match: FeaturedMatch
    
    var body: some View {
        VStack(spacing: 8) {
            Text(match.competition.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            HStack(spacing: 6) {
                // Home Team Box
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
                
                // Live Score Block
                VStack(spacing: 2) {
                    Text(match.displayScore)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.green)
                    Text(match.status)
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.red)
                }
                .frame(width: 50)
                
                // Away Team Box
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
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.15), lineWidth: 1)
        )
    }
}
