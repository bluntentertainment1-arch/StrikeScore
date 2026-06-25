import SwiftUI

struct EditorialView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @State private var selectedArticle: EditorialItem? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.isLoading {
                        ProgressView("Fetching news room...")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    } else if viewModel.editorialItems.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "newspaper")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No news stories available right now.")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                    } else {
                        ForEach(Array(viewModel.editorialItems.enumerated()), id: \.element.id) { index, article in
                            VStack(spacing: 16) {
                                Button(action: { selectedArticle = article }) {
                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(article.headline)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)
                                            Text(article.body)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .lineLimit(3)
                                                .multilineTextAlignment(.leading)
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())

                                // Insert banner ad every 2 articles in the list
                                if (index + 1) % 2 == 0 && index != viewModel.editorialItems.count - 1 {
                                    InlineBannerAdView(
                                        adUnitID: AdMobManager.bannerAdUnitID,
                                        adSize: .standard
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Trending News")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadCMSData()
            }
            .modifier(NavigationWrapperModifier(selectedArticle: $selectedArticle, allArticles: viewModel.editorialItems))
        }
    }
}

// MARK: - Backward Compatible Navigation View Modifier
struct NavigationWrapperModifier: ViewModifier {
    @Binding var selectedArticle: EditorialItem?
    let allArticles: [EditorialItem]

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .navigationDestination(item: $selectedArticle) { article in
                    EditorialDetailView(article: article, allArticles: allArticles)
                }
        } else {
            content
                .sheet(item: $selectedArticle) { article in
                    NavigationStack {
                        EditorialDetailView(article: article, allArticles: allArticles)
                    }
                }
        }
    }
}

// MARK: - Editorial Detail View with Premium Related Stories Layout
struct EditorialDetailView: View {
    let article: EditorialItem
    let allArticles: [EditorialItem]

    // Core selection target to allow recursive detail stacking when tapping related items
    @State private var subSelectedArticle: EditorialItem? = nil

    // Safely randomize real articles directly from the fetched array pool
    private var randomizedRelatedStories: [EditorialItem] {
        allArticles
            .filter { $0.id != article.id }
            .shuffled()
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(article.headline)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(article.datePosted)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()

                Text(article.fullContent.isEmpty ? article.body : article.fullContent)
                    .font(.body)
                    .lineSpacing(6)

                // Banner ad within article content
                InlineBannerAdView(
                    adUnitID: AdMobManager.bannerAdUnitID,
                    adSize: .standard
                )
                .padding(.vertical, 8)

                // --- PREMIUM RELATED STORIES (MATCHES ATTACHED SCREENSHOT) ---
                if !randomizedRelatedStories.isEmpty {
                    Divider()
                        .padding(.vertical, 12)

                    Text("Related Stories")
                        .font(.system(size: 18, weight: .bold))
                        .padding(.bottom, 4)

                    VStack(spacing: 14) {
                        ForEach(Array(randomizedRelatedStories.enumerated()), id: \.element.id) { index, story in
                            VStack(spacing: 14) {
                                Button(action: { subSelectedArticle = story }) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(story.headline)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)

                                        Text(story.body)
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                            .padding(.bottom, 2)

                                        // Row Footer Metadata Line
                                        HStack {
                                            Text("Trending News")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.green)

                                            Circle()
                                                .fill(Color.secondary.opacity(0.4))
                                                .frame(width: 4, height: 4)

                                            Text(story.datePosted)
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(14)
                                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color(.systemGray5).opacity(0.6), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())

                                // Banner ad between related stories
                                if index < randomizedRelatedStories.count - 1 {
                                    InlineBannerAdView(
                                        adUnitID: AdMobManager.bannerAdUnitID,
                                        adSize: .standard
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Article")
        .navigationBarTitleDisplayMode(.inline)
        // Enables deep linking to let users tap a related story and open it instantly
        .modifier(NavigationWrapperModifier(selectedArticle: $subSelectedArticle, allArticles: allArticles))
    }
}
