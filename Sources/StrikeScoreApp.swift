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
    
    // Instantiating the shared viewmodel instance at runtime
    @StateObject private var viewModel = MatchesViewModel()
    @State private var currentPhase: AppFlowState.ViewPhase = .initialSplash
    
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch currentPhase {
                case .initialSplash:
                    // Fallback block if an explicit custom view splash isn't available
                    Color(.systemBackground)
                        .ignoresSafeArea()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    if !hasSeenOnboarding {
                                        currentPhase = .onboardingFlow
                                    } else if !GDPRConsentManager.shared.hasConsent {
                                        currentPhase = .gdprConsentCheck
                                    } else {
                                        currentPhase = .requestPermissions
                                    }
                                }
                            }
                        }
                        
                case .onboardingFlow:
                    // Simple programmatic replacement wrapper fallback to ensure compile safety
                    ZStack {
                        Color.green.ignoresSafeArea()
                        VStack(spacing: 20) {
                            Text("Welcome to StrikeScore")
                                .font(.title.bold())
                                .foregroundColor(.white)
                            Button("Get Started") {
                                hasSeenOnboarding = true
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    if !GDPRConsentManager.shared.hasConsent {
                                        currentPhase = .gdprConsentCheck
                                    } else {
                                        currentPhase = .requestPermissions
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.green)
                            .cornerRadius(10)
                        }
                    }
                    .transition(.opacity)
                    
                case .gdprConsentCheck:
                    ZStack {
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
                    Color(.systemBackground)
                        .ignoresSafeArea()
                        .onAppear {
                            triggerPermissionsPipeline()
                        }
                    
                case .excelPreloading:
                    DataLoadingProgressView()
                        .transition(.opacity)
                        .task {
                            // Seamless preloading function run right here
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
            if newPhase == .active && currentPhase == .mainDashboard {
                Task {
                    await viewModel.loadCMSData()
                }
            }
        }
    }
    
    private func triggerPermissionsPipeline() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    MobileAds.shared.start(completionHandler: nil)
                    // Call without trailing closure block to comply with your source module interface
                    NotificationManager.shared.requestPermission()
                    
                    withAnimation(.easeInOut(duration: 0.4)) {
                        currentPhase = .excelPreloading
                    }
                }
            }
        } else {
            MobileAds.shared.start(completionHandler: nil)
            NotificationManager.shared.requestPermission()
            withAnimation(.easeInOut(duration: 0.4)) {
                currentPhase = .excelPreloading
            }
        }
    }
}
