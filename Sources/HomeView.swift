import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @State private var searchText = ""
    @State private var selectedDate = Date()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Scope Local Subview Callouts
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
                        
                        // Main Match Feed Container Block
                        VStack(alignment: .leading, spacing: 12) {
                            Text(searchText.isEmpty ? "Fixtures Stream" : "Search Results")
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            if viewModel.matches.isEmpty {
                                Text("No matches found.")
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                LazyVStack(spacing: 14) {
                                    ForEach(viewModel.matches) { match in
                                        MatchCardView(match: match, onTap: {
                                            // Handled internally by view layer
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
