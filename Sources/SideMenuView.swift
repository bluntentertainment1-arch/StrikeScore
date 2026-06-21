import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @State private var showAbout = false
    @State private var showContact = false
    @State private var showTerms = false
    @State private var showPrivacy = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { isShowing = false }

            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("App Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 60)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)

                    MenuItem(icon: "square.and.arrow.up", title: "Share App") {
                        shareApp()
                    }

                    MenuItem(icon: "star", title: "Give Us Rating") {
                        openAppStore()
                    }

                    MenuItem(icon: "arrow.clockwise", title: "Check for Updates") {
                        checkForUpdates()
                    }

                    MenuItem(icon: "envelope", title: "Contact Us") {
                        showContact = true
                    }

                    MenuItem(icon: "doc.text", title: "Terms & Conditions") {
                        showTerms = true
                    }

                    MenuItem(icon: "shield", title: "Privacy Policy") {
                        showPrivacy = true
                    }

                    MenuItem(icon: "info.circle", title: "About Us") {
                        showAbout = true
                    }

                    Spacer()

                    Button("Close Drawer") {
                        isShowing = false
                    }
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding()
                }
                .frame(width: 280)
                .background(Color(.systemBackground))

                Spacer()
            }
        }
        .sheet(isPresented: $showAbout) {
            AboutUsView()
        }
        .sheet(isPresented: $showContact) {
            ContactUsView()
        }
        .sheet(isPresented: $showTerms) {
            TermsView()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
    }

    private func shareApp() {
        let url = URL(string: "https://apps.apple.com/app/strikescore")!
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }

    private func openAppStore() {
        if let url = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID") {
            UIApplication.shared.open(url)
        }
    }

    private func checkForUpdates() {
        // Implementation for checking updates
    }
}

struct MenuItem: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .foregroundColor(.primary)
        Divider()
            .padding(.horizontal, 20)
    }
}
