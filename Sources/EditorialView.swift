import SwiftUI

struct EditorialView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @State private var selectedArticle: EditorialItem? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.editorialItems.isEmpty {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading news...")
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                    } else {
                        ForEach(viewModel.editorialItems) { item in
                            EditorialCard(item: item) {
                                selectedArticle = item
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("News")
            .task {
                await viewModel.loadCMSData()
            }
            .sheet(item: $selectedArticle) { article in
                ArticleDetailView(article: article, allArticles: viewModel.editorialItems)
            }
        }
    }
}

// --- INTERACTIVE ARTICLE READER MATRIX ---
struct ArticleDetailView: View {
    let article: EditorialItem
    let allArticles: [EditorialItem]
    @Environment(\.dismiss) private var dismiss
    
    // Track localized context stack to trigger push navigation chain smoothly
    @State private var activeNavigationTarget: EditorialItem? = nil
    
    var relatedStories: [EditorialItem] {
        allArticles.filter { $0.id != article.id }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(article.headline)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(article.datePosted)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Text(article.fullContent)
                        .font(.body)
                        .lineSpacing(6)
                    
                    // RELATED STORIES CAROUSEL LAYER
                    if !relatedStories.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Related Stories")
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(.top, 24)
                            
                            ForEach(relatedStories.prefix(3)) { item in
                                // FIXED: Pressing a related tile now opens it immediately
                                Button(action: { activeNavigationTarget = item }) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(item.headline)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                        
                                        Text(item.body)
                                            .font(.caption)
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
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Article")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            // Continuous detail pushed presentation pipeline context engine
            .navigationDestination(item: $activeNavigationTarget) { nestedArticle in
                ArticleDetailView(article: nestedArticle, allArticles: allArticles)
            }
        }
    }
}
