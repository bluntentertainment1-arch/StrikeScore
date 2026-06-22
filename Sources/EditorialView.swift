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
                // Pass full view model along so the sheet can extract sibling records for related recommendations
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
                
                Text(item.body)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Text(item.datePosted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Read more →")
                        .font(.caption)
                        .foregroundColor(.green)
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
    let allArticles: [EditorialItem]
    @Environment(\.dismiss) private var dismiss
    
    // Grabs items while filtering out the one currently being read
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
                    
                    // FIXED: Dynamic Related News Section Hook
                    if !relatedStories.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Related Stories")
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(.top, 24)
                            
                            ForEach(relatedStories.prefix(3)) { item in
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
