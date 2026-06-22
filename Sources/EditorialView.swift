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
            // Injects the live network array into the target sheet wrapper
            .sheet(item: $selectedArticle) { article in
                ArticleDetailView(article: article, allArticles: viewModel.editorialItems)
            }
        }
    }
}

struct EditorialCard: View {
    let item: EditorialItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                Text(item.headline)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Text(item.body)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                
                HStack {
                    Text(item.datePosted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Read more →")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ArticleDetailView: View {
    let article: EditorialItem
    let allArticles: [EditorialItem] // Receives the shared collection safely
    @Environment(\.dismiss) private var dismiss
    
    // Completely randomizes related modules, hiding the one in active view
    var randomizedRelatedStories: [EditorialItem] {
        let subPool = allArticles.filter { $0.id != article.id }
        return Array(subPool.shuffled().prefix(3))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(article.headline)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(article.datePosted)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Text(article.fullContent)
                        .font(.body)
                        .lineSpacing(6)
                    
                    Divider().padding(.vertical, 8)
                    
                    // --- SHUFFLED RELATED FEED PANEL ---
                    if !randomizedRelatedStories.isEmpty {
                        Text("Related News")
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
                                        .multilineTextAlignment(.leading)
                                    
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
            .navigationTitle("Article")
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
