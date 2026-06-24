import SwiftUI

struct FixturesView: View {
    @EnvironmentObject var viewModel: MatchesViewModel
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var selectedMatch: FeaturedMatch? = nil
    @State private var scheduleSearchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBarContainer(text: $scheduleSearchText, placeholder: "Search teams, leagues, dates...")
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                
                ScrollView {
                    VStack(spacing: 12) {
                        if filteredUpcomingMatches.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 44))
                                    .foregroundColor(.secondary)
                                Text("No matching schedules found")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 80)
                        } else {
                            ForEach(filteredUpcomingMatches) { match in
                                FixtureCard(
                                    match: match,
                                    isFavorited: favoritesManager.isFavorited(match.id)
                                ) {
                                    dismissKeyboard() // Dismisses keyboard safely on item selection
                                    selectedMatch = match
                                } onFavorite: {
                                    favoritesManager.toggleFavorite(match.id)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                    .padding(.bottom, 85)
                }
                // Dismisses the keyboard when scrolling or dragging through results
                .gesture(
                    DragGesture().onChanged { _ in
                        dismissKeyboard()
                    }
                )
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(item: $selectedMatch) { match in
                FeaturedMatchDetailView(match: match)
            }
        }
        .onTapGesture {
            dismissKeyboard() // Dismisses active tracking keyboard states when tapping layout empty spaces
        }
    }

    private var filteredUpcomingMatches: [FeaturedMatch] {
        let upcoming = viewModel.featuredMatches.filter { 
            !$0.isLive && 
            $0.status.uppercased() != "LIVE" && 
            $0.status.uppercased() != "IN_PLAY" && 
            $0.status.uppercased() != "FINISHED" 
        }
        
        if scheduleSearchText.isEmpty {
            return upcoming
        } else {
            let query = scheduleSearchText.lowercased()
            return upcoming.filter { match in
                match.homeTeam.lowercased().contains(query) ||
                match.awayTeam.lowercased().contains(query) ||
                match.competition.lowercased().contains(query) ||
                match.matchDate.lowercased().contains(query)
            }
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct SearchBarContainer: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.gray.opacity(0.8)))
                .foregroundColor(.primary)
                .autocorrectionDisabled()
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(.systemGray5))
        .cornerRadius(10)
    }
}

struct FixtureCard: View {
    let match: FeaturedMatch
    let isFavorited: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(match.competition)
                        .font(.caption2.bold())
                        .foregroundColor(.green)
                    
                    Text("\(match.matchDate) • \(match.matchTime)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(match.homeTeam)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                    Text(match.awayTeam)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Button(action: onFavorite) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .foregroundColor(isFavorited ? .red : .gray)
                }
                .padding(.leading, 8)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
