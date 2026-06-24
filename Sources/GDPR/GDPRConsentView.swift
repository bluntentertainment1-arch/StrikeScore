import SwiftUI

struct GDPRConsentView: View {
    @State private var analyticsConsent = true
    @State private var adsConsent = true
    @Binding var isPresented: Bool // Controls visibility binding at root launch level

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "shield.checkerboard")
                    .font(.system(size: 75))
                    .foregroundColor(.green)

                Text("Privacy Settings")
                    .font(.system(size: 26, weight: .bold, design: .rounded))

                Text("We value your privacy. Please customize your options below to help us support the project while matching store compliance rules.")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 16) {
                    Toggle(isOn: $analyticsConsent) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Anonymous Analytics")
                                .font(.headline)
                            Text("Help us optimize feature loads by sharing crash reports and anonymous performance data.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(.green)

                    Divider()

                    Toggle(isOn: $adsConsent) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Personalized Match Ads")
                                .font(.headline)
                            Text("Receive ad experiences customized to your favorite teams or regional location trends.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(.green)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)

                Spacer()

                Button(action: {
                    // Commit settings to compliance storage
                    GDPRConsentManager.shared.saveUserPreferences(
                        allowAnalytics: analyticsConsent, 
                        allowPersonalizedAds: adsConsent
                    )
                    // Instantly hide the overlay view structure
                    isPresented = false
                }) {
                    Text("Accept & Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}
