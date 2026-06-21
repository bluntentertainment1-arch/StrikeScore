import SwiftUI

struct MatchDetailView: View {
    let match: Match

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Match header
                VStack(spacing: 8) {
                    Text(match.group?.replacingOccurrences(of: "GROUP_", with: "Group ") ?? "World Cup 2026")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    Text(match.displayTime)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(match.isLive ? .red : .primary)
                }
                .padding(.top)

                // Teams and score
                HStack(spacing: 30) {
                    VStack(spacing: 12) {
                        AsyncImage(url: URL(string: match.homeTeam.crest ?? "")) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            Circle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 60, height: 60)

                        Text(match.homeTeam.name)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 4) {
                        Text("\(match.score.fullTime?.displayHome ?? "-") - \(match.score.fullTime?.displayAway ?? "-")")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .monospacedDigit()

                        if match.isLive {
                            Text("LIVE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.15))
                                .cornerRadius(8)
                        }
                    }

                    VStack(spacing: 12) {
                        AsyncImage(url: URL(string: match.awayTeam.crest ?? "")) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            Circle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 60, height: 60)

                        Text(match.awayTeam.name)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)

                // Match info
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(label: "Date", value: match.displayDate)
                    InfoRow(label: "Status", value: match.status)
                    InfoRow(label: "Stage", value: match.stage ?? "Group Stage")

                    if let minute = match.minute {
                        InfoRow(label: "Minute", value: "\(minute)'")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)

                Spacer()
            }
        }
        .navigationTitle("Match Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}
