import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    
    // --- CONNECTED SEARCH & DATE SELECTOR STATE VARIABLES ---
    @State private var searchText = ""
    @State private var selectedDate = 0
    @State private var selectedMatch: FeaturedMatch? = nil
    
    // Computes target date for filtering based on selected day offset
    private var targetFilteringDate: Date {
        Calendar.current.date(byAdding: .day, value: selectedDate, to: Date())!
    }

    // --- WORKING FILTER & CHRONOLOGICAL SORT ENGINE ---
    var filteredMatches: [FeaturedMatch] {
        viewModel.featuredMatches.filter { match in
            // 1. Date Filtering Logic
            let formatter = ISO8601DateFormatter()
            guard let matchDateObj = formatter.date(from: match.matchDate) else { return false }
            let matchIsSameDay = Calendar.current.isDate(matchDateObj, inSameDayAs: targetFilteringDate)
            
            // 2. Search Query Logic
            if searchText.isEmpty {
                return matchIsSameDay
            } else {
                let query = searchText.lowercased()
                let matchesSearch = match.homeTeam.lowercased().contains(query) ||
                                    match.awayTeam.lowercased().contains(query) ||
                                    match.competition.lowercased().contains(query)
                return matchIsSameDay && matchesSearch
            }
        }
        // 3. Chronological Time Sort (e.g., 14:00 before 20:00)
        .sorted { $0.matchTime < $1.matchTime }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // FIXED: Working Active Search Field Layout
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search teams, matches...", text: $searchText)
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
                    VStack(spacing: 12) {
                        // Date selector
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

                        // Featured matches grid - Dynamic Array Rendering
                        if viewModel.isLoading {
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("Loading matches...")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 40)
                        } else if filteredMatches.isEmpty {
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
                    .padding(.vertical)
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
        }
    }
}

// Clean Sub-Component rendering individual grid module positions
struct FeaturedMatchCard: View {
    let featured: FeaturedMatch
    let isFavorited: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    // Home Flag
                    AsyncImage(url: featured.homeFlagURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            Circle().fill(Color(.systemGray4))
                                .overlay(Image(systemName: "sportscourt").font(.system(size: 8)).foregroundColor(.secondary))
                        }
                    }
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())

                    Text(featured.displayScore)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    // Away Flag
                    AsyncImage(url: featured.awayFlagURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            Circle().fill(Color(.systemGray4))
                                .overlay(Image(systemName: "sportscourt").font(.system(size: 8)).foregroundColor(.secondary))
                        }
                    }
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
                }

                VStack(spacing: 2) {
                    Text("\(featured.homeTeam) vs \(featured.awayTeam)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(featured.competition)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    if featured.isLive {
                        HStack(spacing: 2) {
                            Circle().fill(Color.red).frame(width: 6, height: 6)
                            Text("LIVE").font(.system(size: 8, weight: .bold)).foregroundColor(.red)
                        }
                    } else {
                        Text(featured.displayTime)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
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
                        .foregroundColor(isFavorited ? .red : .white)
                        .padding(5)
                        .background(Color.black.opacity(0.4))
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

    var dateLabel: (dayName: String, dayNum: String) {
        let targetDate = Calendar.current.date(byAdding: .day, value: day, to: Date())!
        let f = DateFormatter()
        f.dateFormat = "EEE"
        let name = f.string(from: targetDate).uppercased()
        f.dateFormat = "d"
        let num = f.string(from: targetDate)
        return (name, num)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dateLabel.dayName)
                    .font(.system(size: 10, weight: .bold))
                Text(dateLabel.dayNum)
                    .font(.system(size: 16, weight: .black))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(width: 50, height: 60)
            .background(isSelected ? Color.green : Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}
