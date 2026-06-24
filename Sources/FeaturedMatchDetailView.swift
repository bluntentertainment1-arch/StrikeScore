import SwiftUI
import SafariServices

struct FeaturedMatchDetailView: View {
    let match: FeaturedMatch
    @Environment(\.dismiss) private var dismiss
    @StateObject private var favoritesManager = FavoritesManager.shared
    
    // Tracks the active URL structure to safely trigger Safari context
    @State private var webStreamURL: URL? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    
                    // Scoreboard Banner Row
                    VStack(spacing: 12) {
                        Text(match.competition)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            VStack(spacing: 6) {
                                TeamLogoView(
                                    teamName: match.homeTeam,
                                    localSpreadsheetURL: match.homeFlagURL,
                                    fallbackColor: match.homeFallbackColor,
                                    initials: match.getTeamInitials(from: match.homeTeam),
                                    size: 44
                                )
                                Text(match.homeTeam)
                                    .font(.system(size: 13, weight: .bold))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.85)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Text(match.displayScore)
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .frame(width: 70)
                            
                            VStack(spacing: 6) {
                                TeamLogoView(
                                    teamName: match.awayTeam,
                                    localSpreadsheetURL: match.awayFlagURL,
                                    fallbackColor: match.awayFallbackColor,
                                    initials: match.getTeamInitials(from: match.awayTeam),
                                    size: 44
                                )
                                Text(match.awayTeam)
                                    .font(.system(size: 13, weight: .bold))
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

                    // Core Information Details
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

                    // Links Section Integration
                    if match.hasAdditionalContent {
                        HStack(spacing: 12) {
                            if let l1 = match.link1, let url = cleanAndVerifyURL(l1) {
                                TargetLinkButton(title: "Link 1", action: { webStreamURL = url })
                            }
                            if let l2 = match.link2, let url = cleanAndVerifyURL(l2) {
                                TargetLinkButton(title: "Link 2", action: { webStreamURL = url })
                            }
                            if let l3 = match.link3, let url = cleanAndVerifyURL(l3) {
                                TargetLinkButton(title: "Link 3", action: { webStreamURL = url })
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
                .padding(.vertical)
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
                get: { webStreamURL != nil ? IdentifiableURL(url: webStreamURL!) : nil },
                set: { webStreamURL = $0?.url }
            )) { identifiable in
                SafariViewControllerWrapper(url: identifiable.url)
                    .ignoresSafeArea()
            }
        }
    }
    
    // Safely parse out string formats coming from Excel rows
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

// MARK: - Core Support Frameworks & Elements

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

// Native Apple Safari Controller representation wrapper object
struct SafariViewControllerWrapper: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true
        
        let safariVC = SFSafariViewController(url: url, configuration: config)
        safariVC.preferredControlTintColor = .systemGreen
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// ✅ FIXED: Restored missing InfoDetailRow component implementation
struct InfoDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
                .font(.system(size: 13))
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .font(.system(size: 13))
        }
        .padding(.vertical, 2)
    }
}

// ✅ FIXED: Restored missing TargetLinkButton component implementation
struct TargetLinkButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "play.tv.fill")
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.green)
            .cornerRadius(10)
        }
    }
}
