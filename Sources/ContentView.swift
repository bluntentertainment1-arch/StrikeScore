import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showMenu = false
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem { Label("Home", systemImage: "house") }
                    .tag(0)
                
                LiveMatchesView()
                    .tabItem { Label("Live", systemImage: "sportscourt") }
                    .tag(1)
                
                FixturesView()
                    .tabItem { Label("Schedule", systemImage: "calendar") }
                    .tag(2)
                
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
                    .tabItem { Label("Favorites", systemImage: "heart") }
                    .tag(4)
            }
            .tint(.green)
            // Structural constraint modifier guarantees your subviews layout safely clear of your tab item borders
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 50)
            }
            
            if showMenu {
                SideMenuView(isShowing: $showMenu)
            }
        }
        .overlay(
            VStack {
                HStack {
                    Button(action: { showMenu.toggle() }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(.white) // White text color provides strong contrast under dark theme layouts
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 10)
                    .padding(.top, 4)
                    Spacer()
                }
                Spacer()
            }
        )
    }
}
