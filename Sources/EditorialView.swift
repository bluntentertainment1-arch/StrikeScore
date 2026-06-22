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
                        ForEach(viewModel.editorialItems) { article in
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
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Explore")
            // Navigation destination dynamically swaps your view details without breaking stack context
            .navigationDestination(item: $selectedArticle) { article in
                ArticleDetailView(article: article, allArticles: viewModel.editorialItems, onSelectArticle: { nextArticle in
                    selectedArticle = nextArticle // Changes pages natively on tap!
                })
            }
            .task {
                await viewModel.loadCMSData()
            }
        }
    }
}

struct ArticleDetailView: View {
    let article: EditorialItem
    let allArticles: [EditorialItem]
    var onSelectArticle: (EditorialItem) -> Void
    
    var randomizedRelatedStories: [EditorialItem] {
        allArticles.filter { $0.id != article.id }.shuffled().prefix(3).map { $0 }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(article.headline)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Posted: \(article.datePosted)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider()
                
                Text(article.fullContent.isEmpty ? article.body : article.fullContent)
                    .font(.body)
                    .lineSpacing(6)
                
                Divider().padding(.vertical)
                
                // Related Stories
                if !randomizedRelatedStories.isEmpty {
                    Text("Related Stories")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    VStack(spacing: 12) {
                        ForEach(randomizedRelatedStories) { story in
                            Button(action: { onSelectArticle(story) }) { // Updates action binder
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(story.headline)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    Text(story.body)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Story Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
