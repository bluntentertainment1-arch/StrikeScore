import SwiftUI

struct FavoritesView: View {
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var selectedMatch: FeaturedMatch? = nil
    
    var body: some View {
        NavigationStack {
            Group {
                if favoritesManager.favoriteMatches.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "star.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Favorites Added Yet")
                            .font(.headline)
                        Text("Tap the star icon on any match or team fixture card to add them here for quick access.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    List {
                        ForEach(favoritesManager.favoriteMatches) { match in
                            MatchCardView(match: match)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .onTapGesture {
                                    selectedMatch = match
                                }
                        }
                        .onDelete(perform: deleteFavorite)
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
    
    private func deleteFavorite(at offsets: IndexSet) {
        for index in offsets {
            let match = favoritesManager.favoriteMatches[index]
            favoritesManager.toggleFavorite(match: match)
        }
    }
}
