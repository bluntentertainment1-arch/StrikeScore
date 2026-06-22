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
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                        
                                        Text(article.body)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                        
                                        Text(article.datePosted)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.top, 2)
                                    }
                                    Spacer()
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
            .navigationTitle("News & Updates")
            .task {
                await viewModel.loadCMSData()
            }
            // Passes the complete collection to cleanly generate randomized subsets
            .sheet(item: $selectedArticle) { article in
                ArticleDetailView(article: article, allArticles: viewModel.editorialItems)
            }
        }
    }
}

// --- DETAIL SHEET COMPONENT WITH RANDOMIZED FOOTER SYSTEM ---
struct ArticleDetailView: View {
    let article: EditorialItem
    let allArticles: [EditorialItem]
    @Environment(\.dismiss) private var dismiss
    
    /// Filters out the current selection, completely shuffles the pool, and grabs 3 articles
    var randomizedRelatedStories: [EditorialItem] {
        let secondaryStories = allArticles.filter { $0.id != article.id }
        return Array(secondaryStories.shuffled().prefix(3))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(article.headline)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Published on \(article.datePosted)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Text(article.fullContent)
                        .font(.body)
                        .lineSpacing(6)
                    
                    Divider().padding(.vertical, 8)
                    
                    // --- UNIQUE RANDOMIZED RECENT CORNER ---
                    if !randomizedRelatedStories.isEmpty {
                        Text("Related Stories")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.bottom, 4)
                        
                        VStack(spacing: 12) {
                            ForEach(randomizedRelatedStories) { story in
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
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Editorial Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
