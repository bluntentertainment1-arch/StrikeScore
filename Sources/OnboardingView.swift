import SwiftUI
import AppTrackingTransparency
import AdSupport

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("hasRequestedATT") private var hasRequestedATT = false
    @State private var currentPage = 0
    @State private var showSplash = false
    
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
                
                VStack {
                    Spacer()
                    
                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            hasSeenOnboarding = true
                            requestATT()
                            // Show splash after onboarding completes
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showSplash = true
                            }
                        }
                    }) {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .padding()
                }
            }
        }
    }
    
    private func requestATT() {
        if #available(iOS 14, *) {
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
