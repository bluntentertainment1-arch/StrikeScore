import SwiftUI
import UserNotifications
import GoogleMobileAds
import AppTrackingTransparency

struct AppFlowState {
    enum ViewPhase {
        case initialSplash
        case onboardingFlow
        case gdprConsentCheck
        case requestPermissions
        case excelPreloading
        case mainDashboard
    }
}

@main
struct StrikeScoreApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // ScenePhase lifecycle tracking for memory handling and active background re-syncs
    @Environment(\.scenePhase) private var scenePhase
    
    // Instantiating the single source of truth for your Excel CMS data engine
    @StateObject private var viewModel = MatchesViewModel()
    @State private var currentPhase: AppFlowState.ViewPhase = .initialSplash
    
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch currentPhase {
                case .initialSplash:
                    SplashScreenView(onAnimationComplete: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            if !hasSeenOnboarding {
                                currentPhase = .onboardingFlow
                            } else if !GDPRConsentManager.shared.hasConsent {
                                currentPhase = .gdprConsentCheck
                            } else {
                                currentPhase = .requestPermissions
                            }
                        }
                    })
                    .transition(.opacity)
                        
                case .onboardingFlow:
                    OnboardingView(onOnboardingComplete: {
                        hasSeenOnboarding = true
                        withAnimation(.easeInOut(duration: 0.4)) {
                            if !GDPRConsentManager.shared.hasConsent {
                                currentPhase = .gdprConsentCheck
                            } else {
                                currentPhase = .requestPermissions
                            }
                        }
                    })
                    .transition(.opacity)
                    
                case .gdprConsentCheck:
                    ZStack {
                        // Keeps a clean background under the native-style dialog window box overlay
                        Color(.systemBackground)
                            .ignoresSafeArea()
                        
                        GDPRConsentView(isPresented: Binding(
                            get: { currentPhase == .gdprConsentCheck },
                            set: { _ in
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    currentPhase = .requestPermissions
                                }
                            }
                        ))
                    }
                    .transition(.opacity)
                    
                case .requestPermissions:
                    // Invisible structural bridge state to fire system alerts sequentially on screen
                    Color(.systemBackground)
                        .ignoresSafeArea()
                        .onAppear {
                            triggerPermissionsPipeline()
                        }
                    
                case .excelPreloading:
                    DataLoadingProgressView()
                        .transition(.opacity)
                        .task {
                            // Seamlessly download all match schedules, feeds, and tables from Excel sheet
                            await viewModel.loadCMSData()
                            
                            withAnimation(.easeInOut(duration: 0.4)) {
                                currentPhase = .mainDashboard
                            }
                        }
                        
                case .mainDashboard:
                    ContentView()
                        .environmentObject(viewModel) // Injecting verified source of truth down to all view tabs
                        .transition(.opacity)
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .background:
                AppLogger.shared.log("App entered background phase. Releasing memory caches safely.")
                viewModel.isLoading = false
            case .inactive:
                break
            case .active:
                AppLogger.shared.log("App returned to active focus status.")
                // Refresh data if user returns to app after browsing elsewhere
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
    
    /// Sequentially requests system frameworks on the main thread to prevent alert collision/suppression errors
    private func triggerPermissionsPipeline() {
        if #available(iOS 14, *) {
            // 1. First request App Tracking Transparency choice (App Store required layout placement)
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    AppLogger.shared.log("User authorized personalized profiling metrics.")
                case .denied, .restricted, .notDetermined:
                    AppLogger.shared.log("User opted out of profiling. Serving generic ads baseline safely.")
                @unknown default:
                    break
                }
                
                // 2. Fall back cleanly to Main thread to preserve view hierarchy stability
                DispatchQueue.main.async {
                    // Initialize Mobile Ads SDK (Handles ad profile filtering implicitly based on step 1)
                    MobileAds.shared.start(completionHandler: nil)
                    
                    // 3. Chain custom Push Notification prompt immediately after (Extra closure removed ✅)
                    NotificationManager.shared.requestPermission()
                    
                    // 4. ALWAYS advance to data preloading block regardless of permissions declined
                    withAnimation(.easeInOut(duration: 0.4)) {
                        currentPhase = .excelPreloading
                    }
                }
            }
        } else {
            // Legacy iOS devices fallback structure (Extra closure removed ✅)
            MobileAds.shared.start(completionHandler: nil)
            NotificationManager.shared.requestPermission()
            
            withAnimation(.easeInOut(duration: 0.4)) {
                currentPhase = .excelPreloading
            }
        }
    }
}

// Compact loading display engine layout
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
