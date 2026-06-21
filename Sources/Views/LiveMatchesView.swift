import SwiftUI

struct LiveMatchesView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.matches) { match in
                        LiveMatchRow(match: match, currentTime: $currentTime)
                    }
                }
                .padding()
            }
            .navigationTitle("Live Matches")
            .onReceive(timer) { _ in
                currentTime = Date()
            }
            .task {
                await viewModel.loadData()
                viewModel.startAutoRefresh()
            }
            .onDisappear {
                viewModel.stopAutoRefresh()
            }
        }
    }
}

struct LiveMatchRow: View {
    let match: Match
    @Binding var currentTime: Date
    
    var countdown: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        guard let matchDate = formatter.date(from: match.utcDate) else { return "--:--:--" }
        
        let diff = matchDate.timeIntervalSince(currentTime)
        if diff <= 0 { return "LIVE" }
        
        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        let seconds = Int(diff) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Home team
            VStack(spacing: 8) {
                AsyncImage(url: URL(string: match.homeTeam.crest ?? "")) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                Text(match.homeTeam.name)
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            
            // Center info
            VStack(spacing: 8) {
                if match.isLive {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.caption2)
                        Text("LIVE")
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .cornerRadius(8)
                } else {
                    Text(countdown)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Text("World Cup")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 120)
            
            // Away team
            VStack(spacing: 8) {
                AsyncImage(url: URL(string: match.awayTeam.crest ?? "")) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                Text(match.awayTeam.name)
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}
