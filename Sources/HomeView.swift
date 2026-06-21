import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var selectedDate = 0
    @State private var selectedMatch: FeaturedMatch? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        Text("Search teams, matches...")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

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

                    // Featured matches grid - 3 columns
                    if viewModel.featuredMatches.isEmpty {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading matches...")
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                    } else {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ],
                            spacing: 10
                        ) {
                            ForEach(viewModel.featuredMatches) { match in
                                FeaturedMatchCard(
                                    featured: match,
                                    isFavorited: favoritesManager.isFavorited(match.id)
                                ) {
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

struct DateCell: View {
    let day: Int
    let isSelected: Bool
    let action: () -> Void

    private var date: Date {
        Calendar.current.date(byAdding: .day, value: day, to: Date())!
    }

    private var weekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private var dayNum: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(weekday)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .secondary)
                Text(dayNum)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 55, height: 65)
            .background(isSelected ? Color.green : Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct FeaturedMatchCard: View {
    let featured: FeaturedMatch
    let isFavorited: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                // Home team - smaller flag
                AsyncImage(url: featured.homeFlagURL) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 28, height: 28)
                .clipShape(Circle())

                Text(featured.homeTeam)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                // Score or VS
                if featured.isLive || featured.status == "FINISHED" {
                    Text(featured.displayScore)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(featured.isLive ? .red : .primary)
                } else {
                    Text("vs")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Away team - smaller flag
                AsyncImage(url: featured.awayFlagURL) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 28, height: 28)
                .clipShape(Circle())

                Text(featured.awayTeam)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                // Competition name
                Text(featured.competition)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                // Live badge
                if featured.isLive {
                    HStack(spacing: 2) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text("LIVE")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                // Favorite button
                Button(action: onFavorite) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 12))
                        .foregroundColor(isFavorited ? .red : .gray)
                        .padding(4)
                        .background(Color.black.opacity(0.3))
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
