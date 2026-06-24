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
    
    // Professional ScenePhase lifecycle tracking
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var viewModel = MatchesViewModel()
    @State private var currentPhase: AppFlowState.ViewPhase = .initialSplash
    
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    init() {
        // ✅ FIXED: Using the clean, non-deprecated Swift naming convention
        MobileAds.shared.start(completionHandler: nil)
        
        // Request notification permissions early
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch currentPhase {
                case .initialSplash:
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
                            await viewModel.loadCMSData()
                            
                            withAnimation(.easeInOut(duration: 0.4)) {
                                currentPhase = .mainDashboard
                            }
                        }
                        
                case .mainDashboard:
                    ContentView()
                        .environmentObject(viewModel)
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
