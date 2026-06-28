import SwiftUI

struct FeaturedMatchDetailView: View {
    let match: FeaturedMatch
    @Environment(\.dismiss) private var dismiss
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var displayTargetURL: URL? = nil

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        Text(match.competition)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)

                        HStack(spacing: isPad ? 24 : 12) {
                            VStack(spacing: 6) {
                                TeamLogoView(
                                    teamName: match.homeTeam,
                                    localSpreadsheetURL: match.homeFlagURL,
                                    fallbackColor: match.homeFallbackColor,
                                    initials: match.getTeamInitials(from: match.homeTeam),
                                    size: isPad ? 60 : 44
                                )
                                Text(match.homeTeam)
                                    .font(.system(size: isPad ? 15 : 13, weight: .bold))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.85)
                            }
                            .frame(maxWidth: .infinity)

                            Text(match.displayScore)
                                .font(.system(size: isPad ? 32 : 26, weight: .black, design: .rounded))
                                .frame(width: isPad ? 90 : 70)

                            VStack(spacing: 6) {
                                TeamLogoView(
                                    teamName: match.awayTeam,
                                    localSpreadsheetURL: match.awayFlagURL,
                                    fallbackColor: match.awayFallbackColor,
                                    initials: match.getTeamInitials(from: match.awayTeam),
                                    size: isPad ? 60 : 44
                                )
                                Text(match.awayTeam)
                                    .font(.system(size: isPad ? 15 : 13, weight: .bold))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.85)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6).opacity(0.6))
                    .cornerRadius(14)
                    .padding(.horizontal)
                    .frame(maxWidth: isPad ? 700 : .infinity)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Match Information")
                            .font(.system(size: 15, weight: .bold))
                        Divider()
                        Group {
                            InfoDetailRow(title: "Match Status", value: match.status.uppercased())
                                .foregroundColor(match.isCurrentlyLive ? .red : .primary)
                            InfoDetailRow(title: "Date", value: match.matchDate)
                            InfoDetailRow(title: "Time", value: match.matchTime)
                            if !match.venue.isEmpty {
                                InfoDetailRow(title: "Venue", value: match.venue)
                            }
                            if !match.group.isEmpty {
                                InfoDetailRow(title: "Group", value: match.group)
                            }
                            if !match.stage.isEmpty {
                                InfoDetailRow(title: "Stage", value: match.stage)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                    .padding(.horizontal)
                    .frame(maxWidth: isPad ? 700 : .infinity)

                    if match.hasAdditionalContent {
                        HStack(spacing: 12) {
                            if let l1 = match.link1, let url = cleanAndVerifyURL(l1) {
                                TargetLinkButton(title: "Link 1", action: {
                                    handleLinkTap(url: url)
                                })
                            }
                            if let l2 = match.link2, let url = cleanAndVerifyURL(l2) {
                                TargetLinkButton(title: "Link 2", action: {
                                    handleLinkTap(url: url)
                                })
                            }
                            if let l3 = match.link3, let url = cleanAndVerifyURL(l3) {
                                TargetLinkButton(title: "Link 3", action: {
                                    handleLinkTap(url: url)
                                })
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .frame(maxWidth: isPad ? 700 : .infinity)
                    }

                    InlineBannerAdView(
                        adUnitID: AdMobManager.squareBannerAdUnitID,
                        adSize: .mediumRectangle
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .frame(maxWidth: isPad ? 700 : .infinity)

                    if match.hasMatchBriefing {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "newspaper.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.green)
                                Text("Match Briefing")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            Divider()
                            Text(match.matchBriefing ?? "")
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(14)
                        .padding(.horizontal)
                        .frame(maxWidth: isPad ? 700 : .infinity)
                        .padding(.top, 8)
                    }
                }
                .padding(.vertical)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Match Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        favoritesManager.toggleFavorite(match.id)
                    }) {
                        Image(systemName: favoritesManager.isFavorited(match.id) ? "heart.fill" : "heart")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(favoritesManager.isFavorited(match.id) ? .red : .primary)
                    }
                }
            }
            .fullScreenCover(item: Binding(
                get: { displayTargetURL != nil ? IdentifiableURL(url: displayTargetURL!) : nil },
                set: { displayTargetURL = $0?.url }
            )) { identifiable in
                ExtendedContentWebView(url: identifiable.url, onDismiss: {
                    // Show interstitial when user closes the stream
                    AdMobManager.shared.showLinkInterstitialIfAllowed { }
                })
                .ignoresSafeArea()
            }
        }
    }

    private func handleLinkTap(url: URL) {
        // Track link taps - interstitial shows on 2nd tap or on stream close
        let shouldShowAd = AdMobManager.shared.trackLinkTapAndShouldShowInterstitial()
        if shouldShowAd {
            // On 2nd link tap, show interstitial THEN open stream
            AdMobManager.shared.showLinkInterstitialIfAllowed {
                self.displayTargetURL = url
            }
        } else {
            // First tap - open stream directly, ad will show on close
            self.displayTargetURL = url
        }
    }

    private func cleanAndVerifyURL(_ rawString: String) -> URL? {
        var clean = rawString.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.contains("src=") {
            let pattern = "src=\"([^\"]+)\""
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: clean, options: [], range: NSRange(clean.startIndex..., in: clean)),
               let range = Range(match.range(at: 1), in: clean) {
                clean = String(clean[range])
            }
        }
        return URL(string: clean)
    }
}

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct InfoDetailRow: View {
    let title: String
    let value: String
    var body: some View {
        HStack {
            Text(title).foregroundColor(.secondary).font(.system(size: 13))
            Spacer()
            Text(value).fontWeight(.semibold).font(.system(size: 13))
        }
        .padding(.vertical, 2)
    }
}

struct TargetLinkButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "play.tv.fill").font(.system(size: 12))
                Text(title).font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.green)
            .cornerRadius(10)
        }
    }
}
