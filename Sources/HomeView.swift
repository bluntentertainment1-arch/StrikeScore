import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @State private var searchText = ""
    @State private var selectedDate = Date()
    @State private var selectedTab = 0
    
    // Explicit local copy streams to eliminate .Wrapper binding pipeline breaks
    @State private var currentMatchesList: [FeaturedMatch] = []
    @State private var finishedMatchesList: [FeaturedMatch] = []
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        SearchBarView(searchText: $searchText)
                        
                        DateSelectorBar(selectedDate: $selectedDate)
                        
                        if !finishedMatchesList.isEmpty {
                            FinishedMatchesSection(matches: finishedMatchesList)
                        }
                        
                        // Matches Feed Stream Grid Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text(searchText.isEmpty ? "Fixtures Stream" : "Search Results")
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            if currentMatchesList.isEmpty {
                                Text("No matches found.")
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                LazyVStack(spacing: 14) {
                                    ForEach(currentMatchesList) { match in
                                        MatchCardView(match: match, onTap: {
                                            // Handle interaction detail layers smoothly
                                        })
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .navigationTitle("StrikeScore")
                .task {
                    await viewModel.loadCMSData()
                    // Map local layout states safely outside structural rendering wrappers
                    self.currentMatchesList = viewModel.filteredMatches
                    self.finishedMatchesList = viewModel.recentMatches
                }
            }
            .tabItem { Label("Matches", systemImage: "sportscourt") }
            .tag(0)
            
            StandingsTableView()
                .tabItem { Label("Table", systemImage: "tablecells") }
                .tag(1)
            
            EditorialView()
                .tabItem { Label("News", systemImage: "newspaper") }
                .tag(2)
        }
        .accentColor(.green)
    }
}
