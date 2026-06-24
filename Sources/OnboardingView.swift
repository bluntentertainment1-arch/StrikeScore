import SwiftUI
import AppTrackingTransparency
import AdSupport
import UserNotifications // Added for push notification permissions

struct OnboardingView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("hasRequestedATT") private var hasRequestedATT = false
    @AppStorage("hasRequestedNotifications") private var hasRequestedNotifications = false
    @State private var currentPage = 0
    @State private var showSplash = true
    
    let pages = [
        OnboardingPage(
            image: "sportscourt.fill",
            title: "Live Football Scores",
            description: "Get real-time updates from matches around the world"
        ),
        OnboardingPage(
            image: "newspaper.fill",
            title: "Football News",
            description: "Stay updated with the latest editorial content"
        )
    ]
    
    var body: some View {
        if showSplash {
            SplashScreenView()
                .task {
                    await viewModel.loadCMSData()
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    withAnimation {
                        showSplash = false
                    }
                }
        } else if hasSeenOnboarding {
            ContentView()
                .environmentObject(viewModel)
        } else {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            skipOnboarding()
                        }) {
                            Text("Skip")
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                                .padding()
                        }
                    }
                    Spacer()
                    
                    if currentPage == pages.count - 1 {
                        Button(action: {
                            skipOnboarding()
                        }) {
                            Text("Get Started")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                                .padding(.horizontal, 32)
                        }
                        .padding(.bottom, 60)
                    }
                }
            }
        }
    }
    
    private func skipOnboarding() {
        hasSeenOnboarding = true
        
        // Triggers the system alerts sequentially
        requestNotificationPermission {
            requestATT()
        }
    }
    
    private func requestNotificationPermission(completion: @escaping () -> Void) {
        guard !hasRequestedNotifications else {
            completion()
            return
        }
        hasRequestedNotifications = true
        
        // Request authorization for alerts, badges, and sounds
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                AppLogger.shared.log("Push notifications authorized for daily alerts.")
                // Register with APNs on the main thread if needed for remote tokens
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else if let error = error {
                AppLogger.shared.log("Notification authorization error: \(error.localizedDescription)")
            } else {
                AppLogger.shared.log("Notification authorization denied.")
            }
            
            // Proceed to the ATT request prompt after handling notifications
            completion()
        }
    }
    
    private func requestATT() {
        guard !hasRequestedATT else { return }
        hasRequestedATT = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    AppLogger.shared.log("ATT authorized")
                case .denied:
                    AppLogger.shared.log("ATT denied")
                case .notDetermined:
                    AppLogger.shared.log("ATT not determined")
                case .restricted:
                    AppLogger.shared.log("ATT restricted")
                @unknown default:
                    AppLogger.shared.log("ATT unknown status")
                }
            }
        }
    }
}

struct OnboardingPage {
    let image: String
    let title: String
    let description: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: page.image)
                .font(.system(size: 100))
                .foregroundColor(.green)
            
            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
            
            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
    }
}
