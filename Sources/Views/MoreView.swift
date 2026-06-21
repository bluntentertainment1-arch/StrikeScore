import SwiftUI

struct MoreView: View {
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
                    NavigationLink(destination: GDPRConsentView()) {
                        Label("Privacy Settings", systemImage: "hand.raised")
                    }
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
        }
    }
}
