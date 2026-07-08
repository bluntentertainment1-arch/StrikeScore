import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Last updated: June 20, 2026")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Group {
                        policySection(title: "1. Introduction", content: "StrikeScore (\"we,\" \"our,\" or \"us\") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.")

                        policySection(title: "2. Information We Collect", content: "We may collect information about you in various ways, including: Usage Data (how you interact with the app), Device Information (device type, OS version), and Tracking Data (for usage analytics and personalized ads via third-party SDKs).")

                        policySection(title: "3. How We Use Your Information", content: "We use the information we collect to: Provide and maintain the app, improve user experience, monitor app stability, analyze usage patterns, serve personalized advertisements, and comply with legal obligations.")

                        policySection(title: "4. Third-Party Services", content: "We use third-party services including: Google Analytics for Firebase (to track user engagement and app performance metrics) and Google AdMob (advertising). These services may collect information according to their own privacy policies.")

                        policySection(title: "5. Data Security", content: "We implement appropriate technical and organizational measures to protect your personal data against unauthorized access, alteration, disclosure, or destruction.")

                        policySection(title: "6. Your Rights", content: "Depending on your location, you may have rights to: Access your data, correct inaccuracies, request deletion, opt out of personalized analytics or ads, and lodge complaints with supervisory authorities.")

                        policySection(title: "7. Children's Privacy", content: "Our app is not intended for children under 13. We do not knowingly collect personal information from children under 13.")

                        policySection(title: "8. Changes to This Policy", content: "We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy in the app.")

                        policySection(title: "9. Contact Us", content: "If you have questions about this Privacy Policy, please contact us at: \(AppConstants.contactEmail)")
                    }

                    Text(AppConstants.copyright)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func policySection(title: String, content: String) -> some View {
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
