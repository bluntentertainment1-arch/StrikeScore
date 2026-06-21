import SwiftUI

struct LiveMatchesView: View {
    @StateObject private var viewModel = MatchesViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading && viewModel.matches.isEmpty {
                        ProgressView("Loading matches...")
                            .padding()
                    } else if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        if !viewModel.liveMatches.isEmpty {
                            Text("LIVE NOW")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)

                            ForEach(viewModel.liveMatches) { match in
                                NavigationLink(destination: MatchDetailView(match: match)) {
                                    MatchCardView(match: match)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                            }
                        }

                        if !viewModel.upcomingMatches.isEmpty {
                            Text("UPCOMING")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)

                            ForEach(viewModel.upcomingMatches) { match in
                                NavigationLink(destination: MatchDetailView(match: match)) {
                                    MatchCardView(match: match)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                            }
                        }

                        if !viewModel.finishedMatches.isEmpty {
                            Text("FINISHED")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)

                            ForEach(viewModel.finishedMatches) { match in
                                NavigationLink(destination: MatchDetailView(match: match)) {
                                    MatchCardView(match: match)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Matches")
            .task {
                await viewModel.loadData()
                viewModel.startAutoRefresh()
            }
            .onDisappear {
                viewModel.stopAutoRefresh()
            }
        }
    }
}
