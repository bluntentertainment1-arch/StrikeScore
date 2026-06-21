import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var selectedMatch: FeaturedMatch? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if favoriteMatches.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "heart")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No favorites yet")
                                .foregroundColor(.secondary)
                            Text("Tap the heart icon on any match to add it here")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 100)
                    } else {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ],
                            spacing: 10
                        ) {
                            ForEach(favoriteMatches) { match in
                                FeaturedMatchCard(
                                    featured: match,
                                    isFavorited: true
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
            .navigationTitle("Favorites")
            .task {
                await viewModel.loadCMSData()
            }
            .sheet(item: $selectedMatch) { match in
                FeaturedMatchDetailView(match: match)
            }
        }
    }

    private var favoriteMatches: [FeaturedMatch] {
        viewModel.featuredMatches.filter { favoritesManager.isFavorited($0.id) }
    }
}
