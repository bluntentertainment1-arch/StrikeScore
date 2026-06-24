import SwiftUI
import UserNotifications
import GoogleMobileAds

struct AppFlowState {
    enum ViewPhase {
        case initialSplash
        case onboardingFlow
        case excelPreloading
        case mainDashboard
    }
}

@main
struct StrikeScoreApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // ✅ PROFESSIONAL LIFE CYCLE MONITOR: Tracks active, inactive, and background states
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var viewModel = MatchesViewModel()
    @State private var currentPhase: AppFlowState.ViewPhase = .initialSplash
    
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    // NOTIFICATION & AD REGISTRATION: Fires permissions systems right at boot pipeline context
    init() {
        // Initialize the prefix-less Google Mobile Ads engine core
        MobileAds.sharedInstance.start(completionHandler: nil)
        
        // Request visual layout alert authorization configurations from iOS immediately
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch currentPhase {
                case .initialSplash:
                    // FIX: Listen to your custom view animation completion step safely
                    SplashScreenView(onAnimationComplete: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            if hasSeenOnboarding {
                                currentPhase = .excelPreloading
                            } else {
                                currentPhase = .onboardingFlow
                            }
                        }
                    })
                    .transition(.opacity)
                        
                case .onboardingFlow:
                    OnboardingView(onOnboardingComplete: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            currentPhase = .excelPreloading
                        }
                    })
                    .transition(.opacity)
                    
                case .excelPreloading:
                    DataLoadingProgressView()
                        .transition(.opacity)
                        .task {
                            // Preload Excel data pipeline before launching main view dashboard
                            await viewModel.loadCMSData()
                            
                            withAnimation(.easeInOut(duration: 0.4)) {
                                currentPhase = .mainDashboard
                            }
                        }
                        
                case .mainDashboard:
                    ContentView()
                        .environmentObject(viewModel) // Injected safely down to all child layout hierarchies
                        .transition(.opacity)
                }
            }
        }
        // ✅ PROFESSIONAL LIFECYCLE INTERCEPTOR
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .background:
                /* 
                 The OS has hidden the app UI. We flush tracking, clean cache, 
                 and let iOS freeze/suspend the memory layout properly.
                */
                AppLogger.shared.log("App entered background phase. Releasing memory caches safely.")
                
                // Automatically pause background network fetches if running
                viewModel.isLoading = false
                
            case .inactive:
                /* 
                 The app is transitioning out or user opened Control Center/App Switcher.
                 We hide overlay inputs or save pending changes.
                */
                break
                
            case .active:
                /*
                 App returns to foreground focus. Refresh critical states if 
                 on the main dashboard view phase.
                */
                AppLogger.shared.log("App returned to active focus status.")
                if currentPhase == .mainDashboard {
                    Task {
                        await viewModel.loadCMSData()
                    }
                }
                
            @unknown default:
                break
            }
        }
    }
}

struct DataLoadingProgressView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .tint(.green)
                    .scaleEffect(1.3)
                
                Text("Updating Match Schedules...")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }
}
