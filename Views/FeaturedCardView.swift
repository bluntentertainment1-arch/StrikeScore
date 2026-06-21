import SwiftUI

struct FeaturedCardView: View {
    let featured: FeaturedMatch

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("FEATURED")
                    .font(.caption2)
                    .fontWeight(.black)
                    .foregroundColor(.yellow)
                Spacer()
                Text("\(featured.homeTeam) vs \(featured.awayTeam)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(featured.headline)
                .font(.headline)
                .fontWeight(.bold)
                .lineLimit(2)

            Text(featured.subheadline)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text(featured.matchDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(featured.competition)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.1), Color.yellow.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}
