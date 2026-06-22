import SwiftUI

struct FavoritesView: View {
    private var favoritesManager = FavoritesManager.shared
    @State private var favoriteMatchesList: [FeaturedMatch] = []
    @State private var selectedMatch: FeaturedMatch? = nil
    
    var body: some View {
        NavigationStack {
            Group {
                if favoriteMatchesList.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "star.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Favorites Added Yet")
                            .font(.headline)
                        Text("Tap the star icon on any fixture card to add them here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    List {
                        ForEach(favoriteMatchesList) { match in
                            MatchCardView(match: match, onTap: {
                                selectedMatch = match
                            })
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
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
            .onAppear {
                syncFavorites()
            }
        }
    }
    
    private func syncFavorites() {
        // Reads from the standard favorites collection matching your manager interface
        self.favoriteMatchesList = favoritesManager.favorites
    }
    
    private func deleteFavorite(at offsets: IndexSet) {
        for index in offsets {
            let match = favoriteMatchesList[index]
            // Fixed: Passes the item's identifying String signature value to meet API requirements
            favoritesManager.toggle(match.id)
        }
        syncFavorites()
    }
}
