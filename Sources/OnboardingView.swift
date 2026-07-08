import SwiftUI
import AppTrackingTransparency
import AdSupport
import UserNotifications

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0
    var onOnboardingComplete: () -> Void

    let pages = [
        OnboardingPage(
            image: "sportscourt.fill",
            title: "Live Football Scores",
            description: "Get real-time updates from matches around the world"
        ),
        OnboardingPage(
            image: "calendar.badge.clock",
            title: "Fixtures & Results",
            description: "Explore comprehensive match schedules and past results"
        )
    ]

    var body: some View {
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
                    Button(action: { finishFlow() }) {
                        Text("Skip")
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                            .padding()
                    }
                }
                Spacer()

                if currentPage == pages.count - 1 {
                    Button(action: { finishFlow() }) {
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

    private func finishFlow() {
        hasSeenOnboarding = true
        requestTrackingPermission {
            requestNotificationPermission {
                DispatchQueue.main.async {
                    onOnboardingComplete()
                }
            }
        }
    }

    private func requestTrackingPermission(completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            ATTrackingManager.requestTrackingAuthorization { _ in
                completion()
            }
        }
    }

    private func requestNotificationPermission(completion: @escaping () -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            completion()
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
