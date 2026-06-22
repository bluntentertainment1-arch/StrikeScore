import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Matches / Home Feed
            HomeView()
                .tabItem {
                    // FIXED: Changed systemName to systemImage
                    Label("Matches", systemImage: "sportscourt")
                }
                .tag(0)
            
            // Tab 2: League Tables
            StandingsTableView()
                .tabItem {
                    // FIXED: Changed systemName to systemImage
                    Label("Standings", systemImage: "tablecells")
                }
                .tag(1)
            
            // Tab 3: Saved Favorites
            FavoritesView()
                .tabItem {
                    // FIXED: Changed systemName to systemImage
                    Label("Favorites", systemImage: "star.fill")
                }
                .tag(2)
        }
        .accentColor(.green) // Gives a matching sports-themed accent color to active tabs
    }
}

#Preview {
    ContentView()
}
