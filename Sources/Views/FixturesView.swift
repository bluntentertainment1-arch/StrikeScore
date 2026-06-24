import SwiftUI

struct FixturesView: View {
    // Access the object model directly to prevent proxy binding resolution errors
    @EnvironmentObject var viewModel: MatchesViewModel
    
    private var filteredMatches: [Match] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        
        let todayString = formatter.string(from: Date())
        guard let benchmarkDate = formatter.date(from: todayString) else { return [] }
        
        // Explicitly reading matchDate property names
        return viewModel.allMatches.filter { match in
            guard let matchDate = formatter.date(from: match.matchDate) else { return false }
            return matchDate >= benchmarkDate
        }.sorted { $0.matchDate < $1.matchDate }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if filteredMatches.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Upcoming Matches Scheduled")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(filteredMatches) { match in
                                ScheduledMatchCardRow(match: match)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Schedule")
            .onAppear {
                NotificationManager.shared.scheduleDailyReminders(for: viewModel.allMatches)
            }
        }
    }
}

struct ScheduledMatchCardRow: View {
    let match: Match
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var timeRemainingString: String = ""
    
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                HStack {
                    Text("\(match.matchDate)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    if !match.group.isEmpty {
                        Text(match.group.uppercased())
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(6)
                    }
                }
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            TeamLogoView(teamName: match.homeTeam, size: 20)
                            Text(match.homeTeam)
                                .font(.system(size: 14, weight: .semibold))
                                .lineLimit(1)
                        }
                        HStack(spacing: 8) {
                            TeamLogoView(teamName: match.awayTeam, size: 20)
                            Text(match.awayTeam)
                                .font(.system(size: 14, weight: .semibold))
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(match.matchTime)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                        Text("GMT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        favoritesManager.toggleFavorite(match.id)
                    }) {
                        Image(systemName: favoritesManager.isFavorited(match.id) ? "heart.fill" : "heart")
                            .foregroundColor(favoritesManager.isFavorited(match.id) ? .red : .secondary)
                            .font(.system(size: 16))
                    }
                    .padding(.leading, 4)
                }
            }
            .padding()
            
            if !timeRemainingString.isEmpty {
                HStack {
                    Image(systemName: "clock.badge.checkmark.fill")
                        .font(.system(size: 11))
                    Text(timeRemainingString)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(0.3)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.1))
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(14)
        .onAppear(perform: updateCountdown)
        .onReceive(timer) { _ in updateCountdown() }
    }
    
    private func updateCountdown() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        
        guard let targetDate = formatter.date(from: "\(match.matchDate) \(match.matchTime)") else {
            timeRemainingString = ""
            return
        }
        
        let now = Date()
        if now >= targetDate {
            timeRemainingString = "MATCH LIVE / CONCLUDED"
            return
        }
        
        let components = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: now, to: targetDate)
        
        var parts: [String] = []
        if let d = components.day, d > 0 { parts.append("\(d)d") }
        if let h = components.hour, h > 0 { parts.append("\(h)h") }
        if let m = components.minute, m > 0 { parts.append("\(m)m") }
        if let s = components.second { parts.append("\(s)s") }
        
        timeRemainingString = "STARTS IN: " + parts.joined(separator: " ")
    }
}
