import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Matches / Home Feed
            HomeView()
                .tabItem {
                    Label("Matches", systemName: "sportscourt")
                }
                .tag(0)
            
            // Tab 2: League Tables
            StandingsTableView()
                .tabItem {
                    Label("Standings", systemName: "tablecells")
                }
                .tag(1)
            
            // Tab 3: Saved Favorites
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemName: "star.fill")
                }
                .tag(2)
        }
        .accentColor(.green) // Gives a matching sports-themed accent color to active tabs
    }
}

#Preview {
    ContentView()
}
