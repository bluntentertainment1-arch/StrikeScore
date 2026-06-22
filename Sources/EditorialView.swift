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
                ArticleDetailView(initialArticle: article, allArticles: viewModel.editorialItems)
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
    @State private var article: EditorialItem
    let allArticles: [EditorialItem] 
    @Environment(\.dismiss) private var dismiss
    
    init(initialArticle: EditorialItem, allArticles: [EditorialItem]) {
        self._article = State(initialValue: initialArticle)
        self.allArticles = allArticles
    }
    
    var randomizedRelatedStories: [EditorialItem] {
        let subPool = allArticles.filter { $0.id != article.id }
        return Array(subPool.shuffled().prefix(3))
    }
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(article.headline)
                                .font(.title2)
                                .fontWeight(.bold)
                                .id("TopAnchor") 
                            
                            Text(article.datePosted)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        Text(article.fullContent)
                            .font(.body)
                            .lineSpacing(6)
                        
                        Divider().padding(.vertical, 8)
                        
                        if !randomizedRelatedStories.isEmpty {
                            Text("Related News")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .padding(.bottom, 4)
                            
                            VStack(spacing: 12) {
                                ForEach(randomizedRelatedStories) { story in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            self.article = story
                                            proxy.scrollTo("TopAnchor", anchor: .top)
                                        }
                                    }) {
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
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
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
