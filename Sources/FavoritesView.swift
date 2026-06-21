import SwiftUI

struct FavoritesView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "heart")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No favorites yet")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Favorites")
        }
    }
}
