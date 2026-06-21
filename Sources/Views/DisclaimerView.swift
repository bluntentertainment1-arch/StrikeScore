import SwiftUI

struct DisclaimerView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Disclaimer")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Last updated: June 20, 2026")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Group {
                        disclaimerSection(title: "1. Not Official Affiliation", content: "StrikeScore is an independent application and is not affiliated with, endorsed by, or sponsored by FIFA, UEFA, any national football association, or any football club. All team names, logos, and competition names are trademarks of their respective owners.")

                        disclaimerSection(title: "2. Data Accuracy", content: "While we strive to provide accurate and up-to-date information, we cannot guarantee the accuracy, completeness, or timeliness of any data displayed in the app. Match scores, times, and standings are provided by third-party sources and may be subject to delays or errors.")

                        disclaimerSection(title: "3. No Betting or Gambling", content: "StrikeScore does not facilitate, promote, or endorse sports betting or gambling. The app is intended solely for informational and entertainment purposes. Users must comply with local laws regarding sports betting.")

                        disclaimerSection(title: "4. Intellectual Property", content: "All content, including but not limited to text, graphics, logos, and software, is the property of kidblunt or its content suppliers and is protected by international copyright laws.")

                        disclaimerSection(title: "5. Limitation of Liability", content: "To the maximum extent permitted by law, kidblunt shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising out of or relating to your use of the app.")

                        disclaimerSection(title: "6. Changes to Content", content: "We reserve the right to modify, suspend, or discontinue any part of the app at any time without notice.")

                        disclaimerSection(title: "7. Governing Law", content: "This disclaimer shall be governed by and construed in accordance with the laws of the jurisdiction where kidblunt operates.")

                        disclaimerSection(title: "8. Contact", content: "For questions about this disclaimer, contact us at: \(AppConstants.contactEmail)")
                    }

                    Text(AppConstants.copyright)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Disclaimer")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func disclaimerSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
