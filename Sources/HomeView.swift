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
        Calendar.current.date(byAdding: .day, value: selectedDate, to: Date())!.addingTimeInterval(TimeInterval(Calendar.current.timeZone.secondsFromGMT()))
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
                match.homeTeam.lowercased().contains(query) || match.awayTeam.lowercased().contains(query)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Date picker section
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
                    
                    // Main Fixtures Feed
                    VStack(alignment: .leading, spacing: 14) {
                        Text(searchText.isEmpty ? "Fixtures Feed" : "Search Results")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        if filteredMatches.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "sportscourt.slash")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("No matches scheduled")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                        } else {
                            LazyVStack(spacing: 14) {
                                ForEach(filteredMatches) { match in
                                    MatchCardView(match: match, onTap: {
                                        selectedMatch = match
                                    })
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                    // ENHANCED: Recent Results Block
                    if !finishedMatches.isEmpty && searchText.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Recent Results")
                                    .font(.title2) // Increased text presence
                                    .fontWeight(.black)
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(.yellow)
                            }
                            .padding(.horizontal)
                            
                            LazyVStack(spacing: 14) {
                                ForEach(finishedMatches.prefix(5)) { match in
                                    MatchCardView(match: match, onTap: {
                                        selectedMatch = match
                                    })
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical, 8)
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

// Date Bubble Component Helper
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
            VStack(spacing: 3) {
                Text(dayName)
                    .font(.system(size: 9, weight: .bold))
                Text("\(dateLabel) \(monthName)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(minWidth: 76)
            .background(isSelected ? Color.green : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
        }
    }
}
