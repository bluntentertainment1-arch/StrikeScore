import SwiftUI

struct LiveMatchesView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @State private var selectedMatch: FeaturedMatch? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if viewModel.liveMatches.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "sportscourt")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No matches are currently live")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 100)
                    } else {
                        ForEach(viewModel.liveMatches) { match in
                            // Reusing your optimized card component for consistency
                            MatchCardView(match: match, onTap: {
                                selectedMatch = match
                            })
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Live")
            .navigationBarTitleDisplayMode(.inline)
            // ✅ FIXES THE COMPILER ERROR: Safely start and stop the auto-refresh loops cleanly
            .onAppear {
                viewModel.startAutoRefresh()
            }
            .onDisappear {
                viewModel.stopAutoRefresh()
            }
            .sheet(item: $selectedMatch) { match in
                FeaturedMatchDetailView(match: match)
            }
            .refreshable {
                await viewModel.loadCMSData()
            }
        }
    }
}
