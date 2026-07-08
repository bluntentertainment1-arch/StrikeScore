import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showMenu = false

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            if isPad {
                ipadLayout
            } else {
                iphoneLayout
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
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.65))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 16)
                    .padding(.top, 55)
                    Spacer()
                }
                Spacer()
            }
            .ignoresSafeArea()
        )
    }

    private var iphoneLayout: some View {
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
            TeamExplorerView()
                .tabItem { Label("Teams", systemImage: "shield.fill") }
                .tag(3)
            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "heart") }
                .tag(4)
        }
        .tint(.green)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 50)
        }
    }

    @available(iOS 16.0, *)
    private var ipadLayout: some View {
        NavigationSplitView {
            List {
                NavigationLink(destination: HomeView()) {
                    Label("Home", systemImage: "house")
                }
                NavigationLink(destination: LiveMatchesView()) {
                    Label("Live", systemImage: "sportscourt")
                }
                NavigationLink(destination: FixturesView()) {
                    Label("Schedule", systemImage: "calendar")
                }
                NavigationLink(destination: TeamExplorerView()) {
                    Label("Teams", systemImage: "shield.fill")
                }
                NavigationLink(destination: FavoritesView()) {
                    Label("Favorites", systemImage: "heart")
                }
            }
            .navigationTitle("StrikeScore")
        } detail: {
            HomeView()
        }
        .tint(.green)
    }
}
