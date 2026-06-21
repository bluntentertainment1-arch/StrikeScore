import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            LiveMatchesView()
                .tabItem {
                    Label("Live", systemImage: "sportscourt.fill")
                }

            GroupStandingsView()
                .tabItem {
                    Label("Groups", systemImage: "tablecells.fill")
                }

            FixturesView()
                .tabItem {
                    Label("Fixtures", systemImage: "calendar")
                }

            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis")
                }
        }
        .tint(.green)
    }
}
