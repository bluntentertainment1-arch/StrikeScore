import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { isShowing = false }
            
            // Menu panel
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("App Setting")
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
                        // Navigate to contact
                    }
                    
                    MenuItem(icon: "doc.text", title: "Terms & Conditions") {
                        // Navigate to terms
                    }
                    
                    MenuItem(icon: "shield", title: "Privacy And Policy") {
                        // Navigate to privacy
                    }
                    
                    Spacer()
                    
                    Button("Close Drawer") {
                        isShowing = false
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
                }
                .frame(width: 280)
                .background(Color(.systemBackground))
                
                Spacer()
            }
        }
    }
    
    private func shareApp() {
        let url = URL(string: "https://apps.apple.com/app/strikescore")!
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true)
    }
    
    private func openAppStore() {
        // Open app store for rating
    }
    
    private func checkForUpdates() {
        // Check app version against server
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
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .foregroundColor(.primary)
        Divider()
            .padding(.horizontal, 20)
    }
}
