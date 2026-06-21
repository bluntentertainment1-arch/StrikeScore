import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = MatchesViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Search bar placeholder
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        Text("Search")
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
                                DateCell(day: day)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Featured matches grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(viewModel.featuredMatches) { match in
                            FeaturedMatchCard(featured: match)
                        }
                    }
                    .padding(.horizontal)
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
    
    var body: some View {
        let date = Calendar.current.date(byAdding: .day, value: day, to: Date())!
        let formatter = DateFormatter()
        
        VStack(spacing: 4) {
            Text(formatter.shortWeekdaySymbols[Calendar.current.component(.weekday, from: date) - 1])
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(width: 60, height: 70)
        .background(day == 0 ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(day == 0 ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

struct FeaturedMatchCard: View {
    let featured: FeaturedMatch
    
    var body: some View {
        VStack(spacing: 8) {
            // Home team flag placeholder
            AsyncImage(url: URL(string: "https://flagcdn.com/w80/\(featured.homeTeam.lowercased().prefix(2)).png")) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.3))
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            Text(featured.homeTeam)
                .font(.caption)
                .lineLimit(1)
            
            if featured.competition == "LIVE" {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.caption2)
                    Text("LIVE")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .foregroundColor(.red)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            } else {
                Text(featured.matchDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
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
