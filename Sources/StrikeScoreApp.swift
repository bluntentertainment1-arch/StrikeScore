@main
struct StrikeScoreApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var viewModel = MatchesViewModel()
    @State private var currentPhase: AppFlowState.ViewPhase = .initialSplash
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    // FIX #4 & #8: Initialize AdMobManager early and preload ads
    init() {
        _ = AdMobManager.shared
        AdMobManager.shared.preloadAllAds()
        AdMobManager.shared.startRewardedPromptTimer()
    }

    var body: some Scene {
        // ... rest unchanged
