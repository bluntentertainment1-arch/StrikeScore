import SwiftUI
import AppTrackingTransparency
import AdSupport

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("hasRequestedATT") private var hasRequestedATT = false
    @State private var currentPage = 0
    @State private var showSplash = true // ALWAYS start with splash on launch
    
    let pages = [
        OnboardingPage(
            image: "sportscourt.fill",
            title: "Live Football Scores",
            description: "Get real-time updates from matches around the world"
        ),
        OnboardingPage(
            image: "tablecells.fill",
            title: "Track Standings",
            description: "Follow your favorite teams and leagues with live tables"
        ),
        OnboardingPage(
            image: "bell.fill",
            title: "Match Alerts",
            description: "Never miss a goal with instant notifications"
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
                .onAppear {
                    // Automatically transition out of splash after 2.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation {
                            showSplash = false
                        }
                    }
                }
        } else if hasSeenOnboarding {
            ContentView()
        } else {
            ZStack {
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
        requestATT()
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

// Fallback dummy view if your project lacks an explicit custom structure named SplashScreenView
struct SplashScreenView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                Text("STRIKESCORE")
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .tracking(4)
            }
        }
    }
}
