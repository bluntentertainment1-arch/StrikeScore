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
    @Environment(\.scenePhase) private var scenePhase
    
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
                    GDPRConsentView(isPresented: Binding(
                        get: { currentPhase == .gdprConsentCheck },
                        set: { _ in
                            withAnimation(.easeInOut(duration: 0.4)) {
                                currentPhase = .requestPermissions
                            }
                        }
                    ))
                    .transition(.opacity)
                    
                case .requestPermissions:
                    Color(.systemBackground)
                        .ignoresSafeArea()
                        .onAppear {
                            triggerPermissionsPipeline()
                        }
                    
                case .excelPreloading:
                    DataLoadingProgressView()
                        .transition(.opacity)
                        .task {
                            // Fetch all schedule feeds, fixtures, and editorials before screen loads
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
                AppLogger.shared.log("App entered background phase.")
                viewModel.isLoading = false
            case .inactive:
                break
            case .active:
                AppLogger.shared.log("App returned to active focus.")
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
    
    /// Sequentially requests system frameworks on the main thread to prevent overlay suppression errors
    private func triggerPermissionsPipeline() {
        // 1. Prompt for App Tracking Transparency first
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                AppLogger.shared.log("ATT Tracking choice registered: \(status.rawValue)")
                
                // Now initialized with user profile preferences set
                DispatchQueue.main.async {
                    MobileAds.shared.start(completionHandler: nil)
                    
                    // 2. Chained push notification dialogue request
                    NotificationManager.shared.requestPermission { granted in
                        AppLogger.shared.log("Push permissions status: \(granted)")
                        
                        // 3. Move to safe data download phase
                        withAnimation(.easeInOut(duration: 0.4)) {
                            currentPhase = .excelPreloading
                        }
                    }
                }
            }
        } else {
            // Fallback framework setup for older devices
            MobileAds.shared.start(completionHandler: nil)
            NotificationManager.shared.requestPermission { _ in
                withAnimation(.easeInOut(duration: 0.4)) {
                    currentPhase = .excelPreloading
                }
            }
        }
    }
}
