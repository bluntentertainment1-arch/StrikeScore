import SwiftUI

struct MatchCardView: View {
    let match: Match

    var statusColor: Color {
        if match.isLive { return .red }
        if match.isFinished { return .green }
        return .gray
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.orange)
                    Text("FIFA World Cup 2026")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    if let group = match.group {
                        Text(group.replacingOccurrences(of: "GROUP_", with: "Group "))
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(10)
                    }
                }

                Spacer()

                Text(match.displayTime)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Divider()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            HStack(spacing: 20) {
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: match.homeTeam.crest ?? "")) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 40, height: 40)

                    Text(match.homeTeam.shortName ?? match.homeTeam.name)
                        .font(.system(size: 16, weight: .bold))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                VStack(spacing: 4) {
                    Text("\(match.score.fullTime?.displayHome ?? "-") - \(match.score.fullTime?.displayAway ?? "-")")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .monospacedDigit()

                    if match.isLive {
                        Text("LIVE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
                .frame(width: 100)

                HStack(spacing: 12) {
                    Text(match.awayTeam.shortName ?? match.awayTeam.name)
                        .font(.system(size: 16, weight: .bold))
                        .lineLimit(1)

                    AsyncImage(url: URL(string: match.awayTeam.crest ?? "")) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 40, height: 40)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(match.isLive ? Color.red.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}
