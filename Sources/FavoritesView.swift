import SwiftUI

struct FavoritesView: View {
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var matchesViewModel = MatchesViewModel()
    @State private var selectedMatch: FeaturedMatch? = nil

    private var favoriteMatches: [FeaturedMatch] {
        matchesViewModel.featuredMatches.filter { match in
            favoritesManager.isFavorited(match.id)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if favoriteMatches.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "star.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Favorites Added Yet")
                            .font(.headline)
                    }
                } else {
                    List {
                        ForEach(favoriteMatches) { match in
                            MatchCardView(match: match, onTap: {
                                selectedMatch = match
                            })
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: removeFavoriteMatch)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Favorites")
            .sheet(item: $selectedMatch) { match in
                FeaturedMatchDetailView(match: match)
            }
            .task {
                await matchesViewModel.loadCMSData()
            }
        }
    }

    private func removeFavoriteMatch(at offsets: IndexSet) {
        for index in offsets {
            let match = favoriteMatches[index]
            favoritesManager.toggleFavorite(match.id)
        }
    }
}
