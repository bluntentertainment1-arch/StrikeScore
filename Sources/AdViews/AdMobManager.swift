import SwiftUI
import GoogleMobileAds
import UIKit
import Combine

class AdMobManager: NSObject, UIAdaptivePresentationControllerDelegate, GADFullScreenContentDelegate {
    static let shared = AdMobManager()

    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    static let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    static let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    static let squareBannerAdUnitID = "ca-app-pub-3940256099942544/2435281174"

    private var interstitialAd: InterstitialAd?
    private var rewardedAd: RewardedAd?

    // Interstitial frequency tracking
    private var lastInterstitialShowTime: Date?
    private var hasShownFirstInterstitialThisSession = false
    private let interstitialCooldown: TimeInterval = 120 // 2 minutes (reduced from 4)

    // MARK: - Tap Tracking for Conditional Interstitial Display
    private var fixtureTapCount = 0
    private var articleTapIndices: Set<Int> = []
    private var linkTapCount = 0

    // MARK: - Rewarded Prompt Timer
    private var rewardedPromptTimer: Timer?
    private var isRewardedPromptVisible = false
    private let rewardedPromptInterval: TimeInterval = 300 // 5 minutes
    private var appOpenTime: Date?

    // MARK: - Returning Ad (App Open Ad)
    private var appOpenAd: AppOpenAd?
    private var isShowingAppOpenAd = false
    private var lastAppOpenAdShowTime: Date?
    private let appOpenAdCooldown: TimeInterval = 300 // 5 minutes between app open ads
    private var wasInBackground = false

    private override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - App Lifecycle for Returning Ads
    @objc private func handleAppDidEnterBackground() {
        wasInBackground = true
        stopRewardedPromptTimer()
    }

    @objc private func handleAppDidBecomeActive() {
        // If returning from background after at least 3 seconds, show app open ad
        if wasInBackground {
            wasInBackground = false
            // Small delay to let UI settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showAppOpenAdIfAllowed()
            }
        }
        startRewardedPromptTimer()
    }

    // MARK: - Preload All Ads (call this in AppDelegate or SceneDelegate after UI is ready)
    func preloadAllAds() {
        appOpenTime = Date()
        loadInterstitialAd()
        loadRewardedAd()
        loadAppOpenAd()
        // Start timer after a small delay to ensure ads have time to load
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.startRewardedPromptTimer()
        }
    }

    // MARK: - App Open Ad (Returning Ad)
    func loadAppOpenAd() {
        let request = Request()
        AppOpenAd.load(
            with: AdMobManager.interstitialAdUnitID, // Can reuse interstitial ID or use dedicated app open ID
            request: request,
            orientation: UIInterfaceOrientation.portrait
        ) { [weak self] ad, error in
            if let error = error {
                AppLogger.shared.error("App Open Ad load error: \(error.localizedDescription)")
                return
            }
            self?.appOpenAd = ad
            self?.appOpenAd?.fullScreenContentDelegate = self
            AppLogger.shared.log("App Open Ad loaded successfully")
        }
    }

    func showAppOpenAdIfAllowed() {
        guard !isShowingAppOpenAd else { return }
        guard let appOpenAd = appOpenAd else {
            // Try to load one if not available
            loadAppOpenAd()
            return
        }

        // Check cooldown
        if let lastTime = lastAppOpenAdShowTime {
            guard Date().timeIntervalSince(lastTime) >= appOpenAdCooldown else { return }
        }

        guard let rootVC = getRootViewController() else { return }

        isShowingAppOpenAd = true
        appOpenAd.present(from: rootVC)
        self.appOpenAd = nil
        lastAppOpenAdShowTime = Date()

        // Preload next one
        loadAppOpenAd()
    }

    // MARK: - Interstitial Ad Engine
    func loadInterstitialAd() {
        let request = Request()
        InterstitialAd.load(with: AdMobManager.interstitialAdUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                AppLogger.shared.error("Interstitial load error: \(error.localizedDescription)")
                // Retry after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                    self?.loadInterstitialAd()
                }
                return
            }
            guard let self = self, let ad = ad else { return }
            ad.fullScreenContentDelegate = self
            self.interstitialAd = ad
            AppLogger.shared.log("Interstitial loaded successfully")
        }
    }

    var canShowInterstitial: Bool {
        if !hasShownFirstInterstitialThisSession {
            return interstitialAd != nil
        }
        guard let lastTime = lastInterstitialShowTime else {
            return interstitialAd != nil
        }
        return Date().timeIntervalSince(lastTime) >= interstitialCooldown && interstitialAd != nil
    }

    func showInterstitial(completion: @escaping () -> Void) {
        guard let rootVC = getRootViewController() else {
            completion()
            return
        }

        if let interstitial = interstitialAd {
            interstitial.present(from: rootVC)
            self.interstitialAd = nil
            hasShownFirstInterstitialThisSession = true
            lastInterstitialShowTime = Date()

            // Preload next one immediately
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.loadInterstitialAd()
            }
            completion()
        } else {
            // No ad ready, try to load one and complete
            loadInterstitialAd()
            completion()
        }
    }

    func showInterstitialIfAllowed(completion: @escaping () -> Void) {
        if canShowInterstitial {
            showInterstitial(completion: completion)
        } else {
            // If can't show but no ad loaded, try loading
            if interstitialAd == nil {
                loadInterstitialAd()
            }
            completion()
        }
    }

    // MARK: - Conditional Interstitial Triggers
    @discardableResult
    func trackFixtureTapAndShouldShowInterstitial() -> Bool {
        fixtureTapCount += 1
        if fixtureTapCount == 2 {
            fixtureTapCount = 0
            return true
        }
        return false
    }

    @discardableResult
    func trackArticleTap(at index: Int) -> Bool {
        let targetIndices = [2, 4, 7]
        guard targetIndices.contains(index) else { return false }
        guard !articleTapIndices.contains(index) else { return false }
        articleTapIndices.insert(index)
        return true
    }

    @discardableResult
    func trackLinkTapAndShouldShowInterstitial() -> Bool {
        linkTapCount += 1
        return true
    }

    // MARK: - Rewarded Ad Engine
    func loadRewardedAd() {
        let request = Request()
        RewardedAd.load(with: AdMobManager.rewardedAdUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                AppLogger.shared.error("Rewarded load error: \(error.localizedDescription)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                    self?.loadRewardedAd()
                }
                return
            }
            guard let self = self, let ad = ad else { return }
            ad.fullScreenContentDelegate = self
            self.rewardedAd = ad
            AppLogger.shared.log("Rewarded ad loaded successfully")
        }
    }

    func showRewarded(onRewardEarned: @escaping (Int) -> Void, onClose: @escaping () -> Void) {
        guard let rootVC = getRootViewController() else {
            onClose()
            return
        }

        if let rewarded = rewardedAd {
            rewarded.present(from: rootVC) {
                let reward = rewarded.adReward
                onRewardEarned(reward.amount.intValue)
            }
            self.rewardedAd = nil
            // Preload next one
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.loadRewardedAd()
            }
            onClose()
        } else {
            // No ad ready, try loading and close
            loadRewardedAd()
            onClose()
        }
    }

    // MARK: - Rewarded Prompt Timer
    func startRewardedPromptTimer() {
        guard rewardedPromptTimer == nil else { return }
        // First prompt after 5 minutes, then every 5 minutes
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
        guard rewardedAd != nil else {
            // If no rewarded ad loaded, try to load one and skip this cycle
            loadRewardedAd()
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self, let rootVC = self.getRootViewController() else { return }

            let promptVC = UIHostingController(rootView: RewardedAdPromptView())
            promptVC.modalPresentationStyle = .overFullScreen
            promptVC.modalTransitionStyle = .crossDissolve
            promptVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            self.isRewardedPromptVisible = true
            rootVC.present(promptVC, animated: true)
        }
    }

    func setRewardedPromptVisible(_ visible: Bool) {
        isRewardedPromptVisible = visible
    }

    // MARK: - GADFullScreenContentDelegate
    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        AppLogger.shared.log("Ad impression recorded")
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        isShowingAppOpenAd = false
        // Preload next interstitial if this was one
        if ad is InterstitialAd {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.loadInterstitialAd()
            }
        }
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        AppLogger.shared.error("Ad failed to present: \(error.localizedDescription)")
        isShowingAppOpenAd = false
        // Try to reload
        if ad is InterstitialAd {
            loadInterstitialAd()
        } else if ad is AppOpenAd {
            loadAppOpenAd()
        }
    }

    // MARK: - Window Lookup
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        return rootVC
    }
}
