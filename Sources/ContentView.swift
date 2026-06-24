import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: MatchesViewModel
    @State private var selectedTab = 0
    @State private var showMenu = false
    
    var body: some View {
        // ✅ FIXED: Separating the TabView container prevents parent structural context redraws on device rotation.
        ZStack {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: { showMenu.toggle() }) {
                                    Image(systemName: "line.3.horizontal")
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                }
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
            
            if showMenu {
                SideMenuView(isShowing: $showMenu)
                    .zIndex(1)
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut, value: showMenu)
    }
}
