import SwiftUI

struct MoreView: View {
    @State private var showPrivacySettings = false

    var body: some View {
        NavigationStack {
            List {
                Section("App") {
                    NavigationLink(destination: AboutUsView()) {
                        Label("About Us", systemImage: "info.circle")
                    }

                    NavigationLink(destination: ContactUsView()) {
                        Label("Contact Us", systemImage: "envelope")
                    }
                }

                Section("Legal") {
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Label("Privacy Policy", systemImage: "shield")
                    }

                    NavigationLink(destination: DisclaimerView()) {
                        Label("Disclaimer", systemImage: "exclamationmark.triangle")
                    }
                }

                Section("Settings") {
                    // ✅ FIXED: Changed to a Button layout that opens GDPRConsentView inside a modal sheet
                    Button(action: { showPrivacySettings = true }) {
                        Label("Privacy Settings", systemImage: "hand.raised")
                    }
                    .foregroundColor(.primary)
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(AppConstants.appVersion)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("More")
            // ✅ FIXED: Launches with structural tracking parameters intact for continuous runtime updates
            .sheet(isPresented: $showPrivacySettings) {
                GDPRConsentView(isPresented: $showPrivacySettings)
            }
        }
    }
}
