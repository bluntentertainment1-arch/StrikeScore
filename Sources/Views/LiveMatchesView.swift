import SwiftUI

struct LiveMatchesView: View {
    // ✅ FIX: Changed from @StateObject to @EnvironmentObject to consume shared preloaded data
    @EnvironmentObject var viewModel: MatchesViewModel
    @State private var selectedMatch: FeaturedMatch? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
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
                                MatchCardView(match: match, onTap: {
                                    selectedMatch = match
                                })
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                    .padding(.top, 44) // Generous safe space allocation clear of your menu navigation bounds
                }
            }
            .navigationTitle("Live")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                viewModel.startAutoRefresh()
                Task {
                    await viewModel.loadCMSData() // Instantly updates background feeds upon view load
                }
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
