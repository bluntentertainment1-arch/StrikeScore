import SwiftUI
import FirebaseCore
import GoogleMobileAds
import UserNotifications

@main
struct StrikeScoreApp: App {
    // Shared data engine source of truth across the whole app context
    @StateObject private var viewModel = MatchesViewModel()
    @State private var isPreloadingData = true

    init() {
        // 1. Initialize Firebase for Google Analytics traffic tracking
        FirebaseApp.configure()
        
        // 2. Modern Google Mobile Ads initialization (Prevents deprecation warnings)
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        // 3. Request push notification permission instantly on launch
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isPreloadingData {
                    // Custom Splash Screen holds layout while download finishes
                    SplashPreloaderView()
                        .transition(.opacity)
                } else {
                    // Injecting preloaded view model seamlessly down to views
                    ContentView()
                        .environmentObject(viewModel)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: isPreloadingData)
            .task {
                // 4. Preload the Excel CMS layout right away during splash
                await viewModel.loadCMSData()
                
                // 5. Dismiss preloader seamlessly
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
