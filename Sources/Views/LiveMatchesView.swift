import SwiftUI

struct LiveMatchesView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var selectedMatch: FeaturedMatch? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if liveMatches.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "sportscourt")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No live matches")
                                .foregroundColor(.secondary)
                            Text("Check back during match days")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 100)
                    } else {
                        ForEach(liveMatches) { match in
                            LiveMatchRow(
                                match: match,
                                isFavorited: favoritesManager.isFavorited(match.id)
                            ) {
                                selectedMatch = match
                            } onFavorite: {
                                favoritesManager.toggleFavorite(match.id)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Live Matches")
            .task {
                await viewModel.loadCMSData()
                viewModel.startAutoRefresh()
            }
            .onDisappear {
                viewModel.stopAutoRefresh()
            }
            .sheet(item: $selectedMatch) { match in
                FeaturedMatchDetailView(match: match)
            }
        }
    }

    private var liveMatches: [FeaturedMatch] {
        viewModel.featuredMatches.filter { $0.isLive }
    }
}

struct LiveMatchRow: View {
    let match: FeaturedMatch
    let isFavorited: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Home team
                VStack(spacing: 6) {
                    AsyncImage(url: match.homeFlagURL) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())

                    Text(match.homeTeam)
                        .font(.caption)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)

                // Center info
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("LIVE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)

                    Text(match.displayScore)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()

                    Text(match.competition)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 100)

                // Away team
                VStack(spacing: 6) {
                    AsyncImage(url: match.awayFlagURL) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())

                    Text(match.awayTeam)
                        .font(.caption)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)

                // Favorite button
                Button(action: onFavorite) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundColor(isFavorited ? .red : .gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
