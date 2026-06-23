import SwiftUI
import WebKit

struct FeaturedMatchDetailView: View {
    let match: FeaturedMatch
    @Environment(\.dismiss) private var dismiss
    @StateObject private var favoritesManager = FavoritesManager.shared
    
    @State private var activeTargetURL: String? = nil

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

                    // Button Section matching image layouts
                    if match.hasAdditionalContent {
                        HStack(spacing: 12) {
                            if let l1 = match.link1, !l1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                TargetLinkButton(title: "Link 1", action: { activeTargetURL = l1 })
                            }
                            if let l2 = match.link2, !l2.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                TargetLinkButton(title: "Link 2", action: { activeTargetURL = l2 })
                            }
                            if let l3 = match.link3, !l3.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                TargetLinkButton(title: "Link 3", action: { activeTargetURL = l3 })
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
            .sheet(item: Binding(
                get: { activeTargetURL != nil ? ItemContainer(urlString: activeTargetURL!) : nil },
                set: { activeTargetURL = $0?.urlString }
            )) { container in
                ContentViewer(urlString: container.urlString)
            }
        }
    }
}

struct ItemContainer: Identifiable {
    let id = UUID()
    let urlString: String
}

struct TargetLinkButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.forward.app")
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(.green)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.green.opacity(0.6), lineWidth: 1.5)
            )
            .background(Color.green.opacity(0.04))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContentViewer: View {
    let urlString: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                CustomWebFrameRepresentable(urlString: urlString)
                    .ignoresSafeArea()
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Minimize") { dismiss() }
                        .foregroundColor(.green)
                }
            }
        }
    }
}

struct CustomWebFrameRepresentable: UIViewRepresentable {
    let urlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}

// ✅ Correct component definition with 'title' parameter to match callers
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
