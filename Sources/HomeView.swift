import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Matches Home
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Search & Date Selectors
                        SearchBarView(searchText: $viewModel.searchText)
                        
                        DateSelectorBar(selectedDate: $viewModel.selectedDate)
                        
                        // Finished Matches Carousel Section
                        if !viewModel.finishedMatches.isEmpty {
                            FinishedMatchesSection(matches: viewModel.finishedMatches)
                        }
                        
                        // Current / Live Matches Stream Grid
                        MatchesGridSection(viewModel: viewModel)
                    }
                    .padding(.vertical)
                }
                .navigationTitle("StrikeScore")
                .task {
                    await viewModel.loadCMSData()
                }
            }
            .tabItem {
                Label("Matches", systemImage: "sportscourt")
            }
            .tag(0)
            
            // Tab 2: New League Standings View
            StandingsTableView()
                .tabItem {
                    Label("Table", systemImage: "tablecells")
                }
                .tag(1)
            
            // Tab 3: Editorial News Section
            EditorialView()
                .tabItem {
                    Label("News", systemImage: "newspaper")
                }
                .tag(2)
        }
        .accentColor(.green) // Custom matching layout look
    }
}

// MARK: - Sub-Section Components for Clean Layout Structure

struct SearchBarView: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search matches, teams, competitions...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
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
                    DateCellView(date: date, isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)) {
                        selectedDate = date
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct DateCellView: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.system(size: 11, weight: .semibold))
                Text(date.formatted(.dateTime.day()))
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(width: 50, height: 60)
            .background(isSelected ? Color.green : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
        }
    }
}

struct FinishedMatchesSection: View {
    let matches: [FeaturedMatch]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Results")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)
            
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
                Text(match.competition)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Text(match.homeTeam)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Spacer()
                    Text(match.homeScore ?? "-")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                
                HStack {
                    Text(match.awayTeam)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Spacer()
                    Text(match.awayScore ?? "-")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
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

struct MatchesGridSection: View {
    @ObservedObject var viewModel: MatchesViewModel
    @State private var selectedMatch: FeaturedMatch? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.searchText.isEmpty ? "Fixtures Stream" : "Search Results")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if viewModel.filteredMatches.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "sportscourt.none")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No matches found matching your timeline details.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(viewModel.filteredMatches) { match in
                        MatchCardView(match: match)
                            .onTapGesture {
                                selectedMatch = match
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(match.status.lowercased() == "live" ? Color.green : Color.clear, lineWidth: 1.5)
                                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: match.status)
                            )
                            .padding(.horizontal)
                    }
                }
            }
        }
        .sheet(item: $selectedMatch) { selectedMatch in
            // Dynamic odds calculation initialization logic handled within view detail structure!
            FeaturedMatchDetailView(match: selectedMatch)
        }
    }
}
