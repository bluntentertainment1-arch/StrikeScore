import SwiftUI

struct GDPRConsentView: View {
    @State private var analyticsConsent = false
    @State private var adsConsent = false
    @Environment(\.dismiss) private var dismiss
    
    // ✅ INTEGRATED UPDATE: Added explicit binding wrapper to cleanly support structural push routes
    var isPresented: Binding<Bool>?

    // Convenience initializer to support standard instantiation syntax
    init(isPresented: Binding<Bool>? = nil) {
        self.isPresented = isPresented
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "shield.checkerboard")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text("Privacy Settings")
                    .font(.title)
                    .fontWeight(.bold)

                Text("We value your privacy. Please choose your preferences below.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Analytics", isOn: $analyticsConsent)
                    Text("Help us improve the app by sharing anonymous usage data.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Divider()

                    Toggle("Personalized Ads", isOn: $adsConsent)
                    Text("Receive ads tailored to your interests.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                Spacer()

                Button("Save Preferences") {
                    GDPRConsentManager.shared.giveConsent()
                    if let isPresented = isPresented {
                        isPresented.wrappedValue = false
                    } else {
                        dismiss()
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
