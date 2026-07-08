import SwiftUI

struct AboutUsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)

                    VStack(spacing: 8) {
                        Text("StrikeScore")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Version \(AppConstants.appVersion)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 16) {
                        Text("About")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("StrikeScore is your go-to app for live football scores, fixtures, and results. We bring you real-time updates from the world of football.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }

                    VStack(spacing: 12) {
                        FeatureRow(icon: "bolt.fill", title: "Live Scores", description: "Real-time match updates")
                        FeatureRow(icon: "calendar", title: "Fixtures", description: "Upcoming match schedules")
                        FeatureRow(icon: "checkmark.circle.fill", title: "Results", description: "Past match scores and historical outcomes")
                        FeatureRow(icon: "shield.fill", title: "Team Explorer", description: "Browse all teams and their match history")
                    }
                    .padding(.horizontal)

                    VStack(spacing: 8) {
                        Text("Developed By")
                            .font(.headline)
                        Text("kidblunt")
                            .foregroundColor(.secondary)
                    }

                    Text(AppConstants.copyright)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .padding(.vertical)
            }
            .navigationTitle("About Us")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
