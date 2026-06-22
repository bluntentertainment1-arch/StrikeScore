import SwiftUI

struct EditorialView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @State private var selectedArticle: EditorialItem? = nil
    @Environment(\.dismiss) private var dismiss

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
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Editorial Feed")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadCMSData()
            }
            // --- BACKWARD COMPATIBLE NAVIGATION WRAPPER ---
            .modifier(NavigationWrapperModifier(selectedArticle: $selectedArticle))
        }
    }
}

// MARK: - Backward Compatibility Navigation View Modifier
struct NavigationWrapperModifier: ViewModifier {
    @Binding var selectedArticle: EditorialItem?
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .navigationDestination(item: $selectedArticle) { article in
                    EditorialDetailView(article: article)
                }
        } else {
            content
                .sheet(item: $selectedArticle) { article in
                    NavigationStack {
                        EditorialDetailView(article: article)
                    }
                }
        }
    }
}

// MARK: - Editorial Detail View Detail Screen
struct EditorialDetailView: View {
    let article: EditorialItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(article.headline)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(article.datePosted)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider()
                
                Text(article.fullContent)
                    .font(.body)
                    .lineSpacing(6)
            }
            .padding()
        }
        .navigationTitle("Article")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}
