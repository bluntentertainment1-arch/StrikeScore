import SwiftUI
import FirebaseCore
import GoogleMobileAds

@main
struct StrikeScoreApp: App {
    // 1. Core data engine source of truth
    @StateObject private var viewModel = MatchesViewModel()
    @State private var isPreloadingData = true

    init() {
        // 2. Initialize Firebase SDK for traffic analytics tracking
        FirebaseApp.configure()
        
        // 3. Initialize Google Mobile Ads Framework
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        // 4. Request Push Notification permissions immediately on open
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
                    // Injecting preloaded view model seamlessly down to the views
                    ContentView()
                        .environmentObject(viewModel)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: isPreloadingData)
            .task {
                // 5. Preload the Excel CMS layout right away during splash
                await viewModel.loadCMSData()
                
                // 6. Dismiss preloader seamlessly
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
