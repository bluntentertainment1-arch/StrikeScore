import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @State private var selectedDate = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        Text("Search teams, matches...")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Date selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<7) { day in
                                DateCell(day: day, isSelected: day == selectedDate) {
                                    selectedDate = day
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Featured matches grid
                    if viewModel.featuredMatches.isEmpty {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading matches...")
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                    } else {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ],
                            spacing: 12
                        ) {
                            ForEach(viewModel.featuredMatches) { match in
                                FeaturedMatchCard(featured: match)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("NOVA SOCCER HUB")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadCMSData()
            }
        }
    }
}

struct DateCell: View {
    let day: Int
    let isSelected: Bool
    let action: () -> Void
    
    private var date: Date {
        Calendar.current.date(byAdding: .day, value: day, to: Date())!
    }
    
    private var weekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private var dayNum: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(weekday)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .secondary)
                Text(dayNum)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 60, height: 70)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct FeaturedMatchCard: View {
    let featured: FeaturedMatch
    
    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: featured.homeFlagURL) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.3))
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            Text(featured.homeTeam)
                .font(.caption)
                .lineLimit(1)
            
            if featured.isLive {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                    Text("LIVE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            } else {
                Text("vs")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            AsyncImage(url: featured.awayFlagURL) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.3))
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            Text(featured.awayTeam)
                .font(.caption)
                .lineLimit(1)
            
            Text(featured.competition)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}
