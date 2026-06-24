import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showMenu = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
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
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 50)
            }
            
            if showMenu {
                SideMenuView(isShowing: $showMenu)
            }
        }
        // ✅ FIXED: Realigned structural menu overlay trigger area to keep it clear of device status items and back buttons
        .overlay(
            VStack {
                HStack {
                    Button(action: { showMenu.toggle() }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.65))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 16)
                    .padding(.top, 55) // Pushes container button clear of system level device bars
                    Spacer()
                }
                Spacer()
            }
            .ignoresSafeArea()
        )
    }
}
