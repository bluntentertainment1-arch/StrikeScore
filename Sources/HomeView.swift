import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @State private var searchText = ""
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Localized Structural Inline Search Header Block
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                        TextField("Search matches...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Fixed loop sequence targeting the clear array container property names explicitly
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Fixtures Feed")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        // Clean un-wrapped reading structure layout
                        LazyVStack(spacing: 14) {
                            // FIX: Passing searchText explicitly into the view model function call
                            ForEach(viewModel.filteredMatches(contains: searchText)) { match in
                                MatchCardView(match: match, onTap: {
                                    // Tap routine handled safely in-view
                                })
                                .padding(.horizontal)
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
    }
}
