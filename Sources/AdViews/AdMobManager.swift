import SwiftUI
import GoogleMobileAds
import UIKit
import Combine

class AdMobManager: NSObject, UIAdaptivePresentationControllerDelegate, FullScreenContentDelegate {
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
    private let interstitialCooldown: TimeInterval = 120 // 2 minutes

    // MARK: - Tap Tracking for Conditional Interstitial Display
    private var fixtureTapCount = 0
    private var articleTapIndices: Set<Int> = []
    private var linkTapCount = 0

    // MARK: - Rewarded Prompt Timer
    private var rewardedPromptTimer: Timer?
    private var isRewardedPromptVisible = false
    private let rewardedPromptInterval: TimeInterval = 300 // 5 minutes

    // MARK: - Returning Ad (Interstitial as App Open substitute)
    private var isShowingReturningAd = false
    private var lastReturningAdShowTime: Date?
    private let returningAdCooldown: TimeInterval = 300 // 5 minutes between returning ads
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
        if wasInBackground {
            wasInBackground = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showReturningAdIfAllowed()
            }
        }
        startRewardedPromptTimer()
    }

    // MARK: - Preload All Ads
    func preloadAllAds() {
        loadInterstitialAd()
        loadRewardedAd()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.startRewardedPromptTimer()
        }
    }

    // MARK: - Returning Ad (uses Interstitial as substitute for AppOpenAd)
    func showReturningAdIfAllowed() {
        guard !isShowingReturningAd else { return }

        if let lastTime = lastReturningAdShowTime {
            guard Date().timeIntervalSince(lastTime) >= returningAdCooldown else { return }
        }

        // Use existing interstitial logic for returning ad
        if let interstitial = interstitialAd, canShowInterstitial {
            guard let rootVC = getRootViewController() else { return }
            isShowingReturningAd = true
            interstitial.present(from: rootVC)
            self.interstitialAd = nil
            hasShownFirstInterstitialThisSession = true
            lastInterstitialShowTime = Date()
            lastReturningAdShowTime = Date()
            loadInterstitialAd()
        } else {
            // Try to load one if not available
            loadInterstitialAd()
        }
    }

    // MARK: - Interstitial Ad Engine
    func loadInterstitialAd() {
        let request = Request()
        InterstitialAd.load(with: AdMobManager.interstitialAdUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                AppLogger.shared.error("Interstitial load error: \(error.localizedDescription)")
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

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.loadInterstitialAd()
            }
            completion()
        } else {
            loadInterstitialAd()
            completion()
        }
    }

    func showInterstitialIfAllowed(completion: @escaping () -> Void) {
        if canShowInterstitial {
            showInterstitial(completion: completion)
        } else {
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
                onRewardEarned(rewarded.adReward.amount.intValue)
            }
            self.rewardedAd = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.loadRewardedAd()
            }
            onClose()
        } else {
            loadRewardedAd()
            onClose()
        }
    }

    // MARK: - Rewarded Prompt Timer
    func startRewardedPromptTimer() {
        guard rewardedPromptTimer == nil else { return }
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

    // MARK: - FullScreenContentDelegate
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        AppLogger.shared.log("Ad impression recorded")
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        isShowingReturningAd = false
        if ad is InterstitialAd {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.loadInterstitialAd()
            }
        }
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        AppLogger.shared.error("Ad failed to present: \(error.localizedDescription)")
        isShowingReturningAd = false
        if ad is InterstitialAd {
            loadInterstitialAd()
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
