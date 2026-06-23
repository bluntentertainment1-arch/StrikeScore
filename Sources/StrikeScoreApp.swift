import SwiftUI
import UserNotifications

@main
struct StrikeScoreApp: App {
    // ✅ Safely binds your existing AppDelegate (ATT, AdMob, and Firebase initialization)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Core data source of truth injected into the root layout
    @StateObject private var viewModel = MatchesViewModel()
    @State private var isPreloadingData = true

    init() {
        // ✅ Registers the push notification modal right away when app mounts
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isPreloadingData {
                    // Custom Splash Screen holds layout while data finishes downloading
                    SplashPreloaderView()
                        .transition(.opacity)
                } else {
                    // Injecting preloaded view model seamlessly down to the application views
                    ContentView()
                        .environmentObject(viewModel)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: isPreloadingData)
            .task {
                // Preload the Excel spreadsheet entries right away behind the splash window
                await viewModel.loadCMSData()
                
                // Dismiss splash screen seamlessly once loading finishes
                isPreloadingData = false
            }
        }
    }
}

// Sleek background launch preloader view
struct SplashPreloaderView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                
                Text("StrikeScore")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .tracking(0.5)
                
                ProgressView()
                    .tint(.green)
                    .scaleEffect(1.2)
                    .padding(.top, 8)
            }
        }
    }
}
