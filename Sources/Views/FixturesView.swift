import SwiftUI

struct FixturesView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var selectedMatch: FeaturedMatch? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if upcomingMatches.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "calendar")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No upcoming fixtures")
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 100)
                    } else {
                        ForEach(upcomingMatches) { match in
                            FixtureCard(
                                match: match,
                                isFavorited: favoritesManager.isFavorited(match.id)
                            ) {
                                selectedMatch = match
                            } onFavorite: {
                                favoritesManager.toggleFavorite(match.id)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Schedule")
            .task {
                await viewModel.loadCMSData()
            }
            .sheet(item: $selectedMatch) { match in
                FeaturedMatchDetailView(match: match)
            }
        }
    }

    private var upcomingMatches: [FeaturedMatch] {
        viewModel.featuredMatches.filter { !$0.isLive && $0.status != "FINISHED" }
    }
}

struct FixtureCard: View {
    let match: FeaturedMatch
    let isFavorited: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(match.displayDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(match.displayTime)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .frame(width: 80)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        AsyncImage(url: match.homeFlagURL) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            Circle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 24, height: 24)

                        Text(match.homeTeam)
                            .font(.subheadline)
                            .lineLimit(1)
                    }

                    HStack {
                        AsyncImage(url: match.awayFlagURL) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            Circle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 24, height: 24)

                        Text(match.awayTeam)
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(spacing: 8) {
                    if !match.group.isEmpty {
                        Text(match.group)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(10)
                    }

                    Button(action: onFavorite) {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .font(.system(size: 14))
                            .foregroundColor(isFavorited ? .red : .gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
