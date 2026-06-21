import SwiftUI

struct FeaturedMatchDetailView: View {
    let match: FeaturedMatch
    @Environment(\.dismiss) private var dismiss
    @StateObject private var favoritesManager = FavoritesManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Match header
                    VStack(spacing: 8) {
                        Text(match.competition)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        if match.isLive {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                Text("LIVE")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.top)

                    // Teams and score
                    HStack(spacing: 20) {
                        VStack(spacing: 12) {
                            AsyncImage(url: match.homeFlagURL) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                Circle().fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())

                            Text(match.homeTeam)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 4) {
                            Text(match.displayScore)
                                .font(.system(size: 40, weight: .black, design: .rounded))
                                .monospacedDigit()

                            if match.isLive {
                                Text(match.status)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                        }

                        VStack(spacing: 12) {
                            AsyncImage(url: match.awayFlagURL) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                Circle().fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())

                            Text(match.awayTeam)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)

                    // Match info
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(label: "Date", value: match.displayDate)
                        InfoRow(label: "Time", value: match.displayTime)
                        InfoRow(label: "Venue", value: match.venue)
                        InfoRow(label: "Stage", value: match.stage)
                        if !match.group.isEmpty {
                            InfoRow(label: "Group", value: match.group)
                        }
                        InfoRow(label: "Status", value: match.status)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Favorite button
                    Button(action: {
                        favoritesManager.toggleFavorite(match.id)
                    }) {
                        HStack {
                            Image(systemName: favoritesManager.isFavorited(match.id) ? "heart.fill" : "heart")
                            Text(favoritesManager.isFavorited(match.id) ? "Remove from Favorites" : "Add to Favorites")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(favoritesManager.isFavorited(match.id) ? Color.red : Color.green)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationTitle("Match Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}
