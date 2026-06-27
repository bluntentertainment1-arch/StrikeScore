import SwiftUI          // ✅ ADD THIS LINE
import GoogleMobileAds
import UIKit

class AdMobManager: NSObject {
    static let shared = AdMobManager()

    // Official Google AdMob Production-Safe Testing Keys
    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    static let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    static let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    // Square/Medium Rectangle banner for match detail
    static let squareBannerAdUnitID = "ca-app-pub-3940256099942544/2435281174"

    private var interstitialAd: InterstitialAd?
    private var rewardedAd: RewardedAd?

    // Interstitial frequency tracking
    private var lastInterstitialShowTime: Date?
    private var hasShownFirstInterstitialThisSession = false
    private let interstitialCooldown: TimeInterval = 240 // 4 minutes

    // MARK: - Rewarded Ad Prompt Timer (every 5 minutes)
    private var rewardedPromptTimer: Timer?
    private var isRewardedPromptVisible = false
    private let rewardedPromptInterval: TimeInterval = 300 // 5 minutes

    // MARK: - Tap Tracking for Conditional Interstitial Display
    private var fixtureTapCount = 0
    private var articleTapIndices: Set<Int> = []
    private var linkTapCount = 0

    private override init() {
        super.init()
    }

    /// Preloads all ad units concurrently on app initialization
    func loadAllAds() {
        loadInterstitialAd()
        loadRewardedAd()
        startRewardedPromptTimer()
    }

    // MARK: - Rewarded Ad Prompt Timer
    func startRewardedPromptTimer() {
        // Show first prompt after 5 minutes, then repeat every 5 minutes
        rewardedPromptTimer = Timer.scheduledTimer(withTimeInterval: rewardedPromptInterval, repeats: true) { [weak self] _ in
            self?.triggerRewardedPrompt()
        }
    }

    func stopRewardedPromptTimer() {
        rewardedPromptTimer?.invalidate()
        rewardedPromptTimer = nil
    }

    private func triggerRewardedPrompt() {
        guard !isRewardedPromptVisible else { return }
        
        DispatchQueue.main.async {
            guard let rootVC = self.getRootViewController() else { return }
            
            let promptVC = UIHostingController(rootView: RewardedAdPromptView())
            promptVC.modalPresentationStyle = .formSheet
            promptVC.isModalInPresentation = false
            
            // For iPad, make it a nice centered card
            if UIDevice.current.userInterfaceIdiom == .pad {
                promptVC.preferredContentSize = CGSize(width: 400, height: 480)
            }
            
            self.isRewardedPromptVisible = true
            rootVC.present(promptVC, animated: true)
            
            // Reset flag when dismissed (observed via presentationController)
            promptVC.presentationController?.delegate = self
        }
    }

    // MARK: - Interstitial Ad Engine
    func loadInterstitialAd() {
        let request = Request()
        InterstitialAd.load(with: AdMobManager.interstitialAdUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                AppLogger.shared.error("Interstitial Ad missing or failed to preload: \(error.localizedDescription)")
                return
            }
            self?.interstitialAd = ad
        }
    }

    /// Checks if interstitial can be shown based on frequency rules
    var canShowInterstitial: Bool {
        // Always allow first interstitial of the session
        if !hasShownFirstInterstitialThisSession {
            return interstitialAd != nil
        }
        // For subsequent shows, enforce 4-minute cooldown
        guard let lastTime = lastInterstitialShowTime else {
            return interstitialAd != nil
        }
        let elapsed = Date().timeIntervalSince(lastTime)
        return elapsed >= interstitialCooldown && interstitialAd != nil
    }

    func showInterstitial(completion: @escaping () -> Void) {
        guard let rootVC
