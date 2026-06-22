import SwiftUI

struct FavoritesView: View {
    // Use standard tracking wrapper properties that don't rely on `.favorites` arrays
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @State private var selectedMatch: FeaturedMatch? = nil
    
    var body: some View {
        NavigationStack {
            Group {
                // Adjusting to read the core data models tracking configuration directly 
                if favoritesManager.favoriteMatches.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "star.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Favorites Added Yet")
                            .font(.headline)
                    }
                } else {
                    List {
                        ForEach(favoritesManager.favoriteMatches) { match in
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
        }
    }
    
    private func removeFavoriteMatch(at offsets: IndexSet) {
        for index in offsets {
            let match = favoritesManager.favoriteMatches[index]
            // Access custom manipulation routines matching your API signature profiles directly
            favoritesManager.removeFavorite(match: match)
        }
    }
}
