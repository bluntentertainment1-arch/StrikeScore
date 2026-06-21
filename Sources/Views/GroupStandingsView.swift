import SwiftUI

struct GroupStandingsView: View {
    @StateObject private var viewModel = MatchesViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading && viewModel.standings.isEmpty {
                        ProgressView("Loading standings...")
                            .padding()
                    } else if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        ForEach(viewModel.standings) { standing in
                            GroupStandingCard(standing: standing)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Standings")
            .task {
                await viewModel.loadData()
            }
        }
    }
}

struct GroupStandingCard: View {
    let standing: GroupStanding

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(standing.displayGroup)
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            Divider()
                .padding(.horizontal, 16)

            ForEach(standing.table) { team in
                TeamStandingRow(team: team)
                    .padding(.horizontal, 16)
            }
            .padding(.bottom, 12)
        }
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct TeamStandingRow: View {
    let team: TeamStanding

    var body: some View {
        HStack(spacing: 12) {
            Text("\(team.position)")
                .font(.system(size: 14, weight: .bold))
                .frame(width: 24)

            AsyncImage(url: URL(string: team.team.crest ?? "")) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.3))
            }
            .frame(width CacheService.shared.load([EditorialItem].self, forKey: "cachedEditorial") {
            self.editorialItems = cached
        }
    }

    func startAutoRefresh() {
        apiTimer = Timer.scheduledTimer(withTimeInterval: AppConfig.apiPollInterval, repeats: true) { _ in
            Task { await self.loadData() }
        }

        cmsTimer = Timer.scheduledTimer(withTimeInterval: AppConfig.excelRefreshInterval, repeats: true) { _ in
            Task { await self.loadCMSData() }
        }
    }

    func stopAutoRefresh() {
        apiTimer?.invalidate()
        cmsTimer?.invalidate()
        apiTimer = nil
        cmsTimer = nil
    }
}
