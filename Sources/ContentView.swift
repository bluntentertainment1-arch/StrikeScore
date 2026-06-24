import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showMenu = false
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(0)
                
                LiveMatchesView()
                    .tabItem {
                        Label("Live", systemImage: "sportscourt")
                    }
                    .tag(1)
                
                FixturesView()
                    .tabItem {
                        Label("Schedule", systemImage: "calendar")
                    }
                    .tag(2)
                
                // Keep your blazing Explore Tab Menu Setup completely intact
                EditorialView()
                    .tabItem {
                        VStack {
                            Image(systemName: "flame.circle.fill")
                                .symbolRenderingMode(.multicolor)
                            Text("Explore")
                        }
                    }
                    .tag(3)
                
                FavoritesView()
                    .tabItem {
                        Label("Favorites", systemImage: "heart")
                    }
                    .tag(4)
            }
            .tint(.green)
            
            // Side menu overlay
            if showMenu {
                SideMenuView(isShowing: $showMenu)
            }
        }
        .overlay(
            // Hamburger button configuration
            VStack {
                HStack {
                    Button(action: { showMenu.toggle() }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding()
                    }
                    Spacer()
                }
                Spacer()
            }
        )
    }
}
