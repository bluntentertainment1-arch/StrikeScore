import SwiftUI

struct TermsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Terms & Conditions")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Last updated: June 20, 2026")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Group {
                        termsSection(title: "1. Acceptance of Terms", content: "By downloading and using StrikeScore, you agree to these Terms & Conditions. If you do not agree, please do not use the app.")

                        termsSection(title: "2. Use of the App", content: "StrikeScore provides football scores, fixtures, and news for informational purposes. The app is free to use with optional advertisements.")

                        termsSection(title: "3. Intellectual Property", content: "All content, including logos, text, and graphics, is the property of Blunt Entertainment or its licensors. You may not reproduce or distribute without permission.")

                        termsSection(title: "4. Disclaimer", content: "While we strive for accuracy, we do not guarantee the completeness or timeliness of match data. Use the app at your own risk.")

                        termsSection(title: "5. Limitation of Liability", content: "Blunt Entertainment shall not be liable for any damages arising from the use or inability to use the app.")

                        termsSection(title: "6. Changes to Terms", content: "We may update these terms at any time. Continued use of the app constitutes acceptance of the updated terms.")

                        termsSection(title: "7. Contact", content: "For questions about these terms, contact us at: \(AppConstants.contactEmail)")
                    }

                    Text(AppConstants.copyright)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Terms & Conditions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func termsSection(title: String, content: String) -> some View {
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
