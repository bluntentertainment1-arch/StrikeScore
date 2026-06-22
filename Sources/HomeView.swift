import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @State private var searchText = ""
    @State private var selectedDate = Date() // Fixed: Kept local to bypass wrapper dependencies
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        SearchBarView(searchText: $searchText)
                        
                        DateSelectorBar(selectedDate: $selectedDate)
                        
                        if !viewModel.finishedMatches.isEmpty {
                            FinishedMatchesSection(matches: viewModel.finishedMatches)
                        }
                        
                        // Matches Feed Stream Grid
                        MatchesGridSection(viewModel: viewModel, searchText: searchText)
                    }
                    .padding(.vertical)
                }
                .navigationTitle("StrikeScore")
                .task {
                    await viewModel.loadCMSData()
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

// MARK: - Extracted Feed Grid View

struct MatchesGridSection: View {
    @ObservedObject var viewModel: MatchesViewModel
    let searchText: String
    @State private var selectedMatch: FeaturedMatch? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(searchText.isEmpty ? "Fixtures Stream" : "Search Results")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            // Fixed: Safely accesses elements via base model collection directly
            if viewModel.matches.isEmpty {
                Text("No matches found.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(viewModel.matches) { match in
                        MatchCardView(match: match, onTap: {
                            selectedMatch = match
                        })
                        .padding(.horizontal)
                    }
                }
            }
        }
        .sheet(item: $selectedMatch) { match in
            FeaturedMatchDetailView(match: match)
        }
    }
}

// MARK: - Shared Shell Subviews

struct SearchBarView: View {
    @Binding var searchText: String
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField("Search matches...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct DateSelectorBar: View {
    @Binding var selectedDate: Date
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<7) { index in
                    let date = Calendar.current.date(byAdding: .day, value: index - 3, to: Date()) ?? Date()
                    Button(action: { selectedDate = date }) {
                        VStack(spacing: 4) {
                            Text(date.formatted(.dateTime.weekday(.abbreviated))).font(.system(size: 11, weight: .semibold))
                            Text(date.formatted(.dateTime.day())).font(.system(size: 16, weight: .bold))
                        }
                        .frame(width: 50, height: 60)
                        .background(Calendar.current.isDate(date, inSameDayAs: selectedDate) ? Color.green : Color(.systemGray6))
                        .foregroundColor(Calendar.current.isDate(date, inSameDayAs: selectedDate) ? .white : .primary)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FinishedMatchesSection: View {
    let matches: [FeaturedMatch]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Results").font(.title3).fontWeight(.bold).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(matches) { match in
                        FinishedMatchCarouselCard(match: match)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct FinishedMatchCarouselCard: View {
    let match: FeaturedMatch
    @State private var showDetail = false
    var body: some View {
        Button(action: { showDetail = true }) {
            VStack(alignment: .leading, spacing: 8) {
                Text(match.competition).font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)
                HStack {
                    Text(match.homeTeam).font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text(match.homeScore ?? "-").font(.system(size: 14, weight: .bold))
                }
                HStack {
                    Text(match.awayTeam).font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text(match.awayScore ?? "-").font(.system(size: 14, weight: .bold))
                }
            }
            .padding()
            .frame(width: 160, height: 100)
            .background(Color(.systemGray6))
            .cornerRadius(14)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showDetail) {
            FeaturedMatchDetailView(match: match)
        }
    }
}
