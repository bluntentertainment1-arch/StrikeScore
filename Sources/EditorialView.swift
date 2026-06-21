import SwiftUI

struct EditorialView: View {
    @StateObject private var viewModel = MatchesViewModel()
    
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
                            EditorialCard(item: item)
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
        }
    }
}

struct EditorialCard: View {
    let item: EditorialItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.headline)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(item.body)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(4)
            
            HStack {
                Text(item.datePosted)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}
