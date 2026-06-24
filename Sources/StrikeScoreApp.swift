import SwiftUI
import UserNotifications

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
    
    @StateObject private var viewModel = MatchesViewModel()
    @State private var currentPhase: AppFlowState.ViewPhase = .initialSplash
    
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch currentPhase {
                case .initialSplash:
                    // ✅ FIX: Using your exact custom screen view from your project files folder
                    SplashScreenView()
                        .transition(.opacity)
                        .onAppear {
                            // Enforce visual sequence: Show your Splash first for 2.5 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    if hasSeenOnboarding {
                                        currentPhase = .excelPreloading
                                    } else {
                                        currentPhase = .onboardingFlow
                                    }
                                }
                            }
                        }
                        
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
                            // Preload Excel spreadsheet records safely inside its designated phase
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
    }
}

// Phase 3 View: Dedicated Data Synchronization Preloader that displays right after Splash/Onboarding
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
