import SwiftUI

struct LiveMatchesView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var selectedMatch: FeaturedMatch? = nil
    
    // Smooth pulse state variable to drive the custom navigation dot animation
    @State private var pulseAnimation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if liveMatches.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "sportscourt")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No live matches")
                                .foregroundColor(.secondary)
                            Text("Check back during match days")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 100)
                    } else {
                        ForEach(liveMatches) { match in
                            LiveMatchRow(
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
            // FIXED: Title updated to "Live"
            .navigationTitle("Live")
            .navigationBarTitleDisplayMode(.inline)
            // Added glowing green icon next to the navigation layout header
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .scaleEffect(pulseAnimation ? 1.3 : 0.9)
                            .opacity(pulseAnimation ? 0.5 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                            .onAppear {
                                pulseAnimation = true
                            }
                    }
                }
            }
            .task {
                await viewModel.loadCMSData()
                viewModel.startAutoRefresh()
            }
            .onDisappear {
                viewModel.stopAutoRefresh()
            }
            .sheet(item: $selectedMatch) { match in
                FeaturedMatchDetailView(match: match)
            }
        }
    }

    private var liveMatches: [FeaturedMatch] {
        viewModel.featuredMatches.filter { $0.isLive }
    }
}

struct LiveMatchRow: View {
    let match: FeaturedMatch
    let isFavorited: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Home team
                VStack(spacing: 6) {
                    AsyncImage(url: match.homeFlagURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())

                    Text(match.homeTeam)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)

                // Center info
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text("LIVE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)

                    Text(match.displayScore)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()

                    Text(match.competition)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(width: 100)

                // Away team
                VStack(spacing: 6) {
                    AsyncImage(url: match.awayFlagURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())

                    Text(match.awayTeam)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)

                // Favorite button
                Button(action: onFavorite) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundColor(isFavorited ? .red : .gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
