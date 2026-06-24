import SwiftUI
import UserNotifications

@main
struct StrikeScoreApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var viewModel = MatchesViewModel()
    @State private var isPreloadingData = true
    
    // Core persistent storage properties to keep track of user progression state
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    init() {
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isPreloadingData {
                    SplashPreloaderView()
                        .transition(.opacity)
                } else {
                    // Logic routing state switch block
                    if hasSeenOnboarding {
                        ContentView()
                            .environmentObject(viewModel)
                            .transition(.opacity)
                    } else {
                        OnboardingView()
                            .environmentObject(viewModel)
                            .transition(.opacity)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.4), value: isPreloadingData)
            .task {
                // Preload Excel spreadsheet records behind splash view layout context
                await viewModel.loadCMSData()
                
                // Enforce a minor padding delay for smooth visual transition
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                
                isPreloadingData = false
            }
        }
    }
}

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
