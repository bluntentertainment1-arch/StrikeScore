import SwiftUI
import GoogleMobileAds
import UIKit

class AdMobManager: NSObject, FullScreenContentDelegate {
    static let shared = AdMobManager()

    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    static let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    static let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    static let squareBannerAdUnitID = "ca-app-pub-3940256099942544/2435281174"

    // MARK: - Ad Instances
    private var interstitialAd: InterstitialAd?
    private var returningInterstitialAd: InterstitialAd?
    private var rewardedAd: RewardedAd?

    // MARK: - Independent Cooldowns
    private var lastFixtureInterstitialTime: Date?
    private var lastArticleInterstitialTime: Date?
    private var lastLinkInterstitialTime: Date?
    private var lastReturningAdTime: Date?

    private let fixtureCooldown: TimeInterval = 60
    private let articleCooldown: TimeInterval = 60
    private let linkCooldown: TimeInterval = 30
    private let returningAdCooldown: TimeInterval = 300

    // MARK: - Tap Tracking
    private var fixtureTapCount = 0
    private var articleTapIndices: Set<Int> = []
    private var linkTapCount = 0

    // MARK: - Rewarded Prompt Timer
    private var rewardedPromptTimer: Timer?
    private var isRewardedPromptVisible = false
    private let rewardedPromptInterval: TimeInterval = 180 // 3 minutes

    // MARK: - Returning Ad Tracking
    private var wasInBackground = false

    // MARK: - Ad Loading Completion Handlers
    private var interstitialLoadCompletion: (() -> Void)?
    private var returningInterstitialLoadCompletion: (() -> Void)?
    private var rewardedOnEarned: ((Int) -> Void)?
    private var rewardedOnClose: (() -> Void)?

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

    // MARK: - App Lifecycle
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
        loadReturningInterstitialAd()
        loadRewardedAd()
    }

    // MARK: - Interstitial Ad Loading
    func loadInterstitialAd() {
        guard interstitialAd == nil else { return }
        let request = Request()
        InterstitialAd.load(with: AdMobManager.interstitialAdUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            if let error = error {
                AppLogger.shared.error("Interstitial load error: \(error.localizedDescription)")
                self.interstitialAd = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                    self?.loadInterstitialAd()
                }
                return
            }
            guard let ad = ad else {
                self.interstitialAd = nil
                return
            }
            ad.fullScreenContentDelegate = self
            self.interstitialAd = ad
            AppLogger.shared.log("Interstitial loaded successfully")
            if let completion = self.interstitialLoadCompletion {
                self.interstitialLoadCompletion = nil
                self.showLoadedInterstitial(completion: completion)
            }
        }
    }

    // MARK: - Fixture Interstitial (waits for ad if not loaded)
    func showFixtureInterstitialIfAllowed(completion: @escaping () -> Void) {
        if let lastTime = lastFixtureInterstitialTime {
            guard Date().timeIntervalSince(lastTime) >= fixtureCooldown else {
                completion()
                return
            }
        }
        if interstitialAd != nil {
            showLoadedInterstitial(completion: completion)
        } else {
            AppLogger.shared.log("Fixture interstitial not ready, waiting for load...")
            interstitialLoadCompletion = completion
            loadInterstitialAd()
        }
    }

    private func showLoadedInterstitial(completion: @escaping () -> Void) {
        guard let rootVC = getRootViewController(), let interstitial = interstitialAd else {
            completion()
            return
        }
        interstitial.present(from: rootVC)
        self.interstitialAd = nil
        lastFixtureInterstitialTime = Date()
        loadInterstitialAd()
        completion()
    }

    // MARK: - Article Interstitial (waits for ad if not loaded)
    func showArticleInterstitialIfAllowed(completion: @escaping () -> Void) {
        if let lastTime = lastArticleInterstitialTime {
            guard Date().timeIntervalSince(lastTime) >= articleCooldown else {
                completion()
                return
            }
        }
        if interstitialAd != nil {
            showLoadedInterstitial(completion: completion)
        } else {
            AppLogger.shared.log("Article interstitial not ready, waiting for load...")
            interstitialLoadCompletion = completion
            loadInterstitialAd()
        }
    }

    // MARK: - Link Interstitial (waits for ad if not loaded)
    func showLinkInterstitialIfAllowed(completion: @escaping () -> Void) {
        if let lastTime = lastLinkInterstitialTime {
            guard Date().timeIntervalSince(lastTime) >= linkCooldown else {
                completion()
                return
            }
        }
        if interstitialAd != nil {
            showLoadedInterstitial(completion: completion)
        } else {
            AppLogger.shared.log("Link interstitial not ready, waiting for load...")
            interstitialLoadCompletion = completion
            loadInterstitialAd()
        }
    }

    // MARK: - Returning Interstitial Ad
    func loadReturningInterstitialAd() {
        guard returningInterstitialAd == nil else { return }
        let request = Request()
        InterstitialAd.load(with: AdMobManager.interstitialAdUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            if let error = error {
                AppLogger.shared.error("Returning interstitial load error: \(error.localizedDescription)")
                self.returningInterstitialAd = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                    self?.loadReturningInterstitialAd()
                }
                return
            }
            guard let ad = ad else {
                self.returningInterstitialAd = nil
                return
            }
            ad.fullScreenContentDelegate = self
            self.returningInterstitialAd = ad
            AppLogger.shared.log("Returning interstitial loaded successfully")
            if let completion = self.returningInterstitialLoadCompletion {
                self.returningInterstitialLoadCompletion = nil
                completion()
            }
        }
    }

    func showReturningAdIfAllowed() {
        if let lastTime = lastReturningAdTime {
            guard Date().timeIntervalSince(lastTime) >= returningAdCooldown else {
                if returningInterstitialAd == nil {
                    loadReturningInterstitialAd()
                }
                return
            }
        }
        if returningInterstitialAd != nil {
            showLoadedReturningInterstitial()
        } else {
            returningInterstitialLoadCompletion = { [weak self] in
                self?.showReturningAdIfAllowed()
            }
            loadReturningInterstitialAd()
        }
    }

    private func showLoadedReturningInterstitial() {
        guard let rootVC = getRootViewController(), let interstitial = returningInterstitialAd else { return }
        interstitial.present(from: rootVC)
        self.returningInterstitialAd = nil
        lastReturningAdTime = Date()
        loadReturningInterstitialAd()
    }

    // MARK: - Tracking Methods
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
        if linkTapCount == 2 {
            linkTapCount = 0
            return true
        }
        return false
    }

    // MARK: - Rewarded Ad Engine
    func loadRewardedAd() {
        guard rewardedAd == nil else { return }
        let request = Request()
        RewardedAd.load(with: AdMobManager.rewardedAdUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            if let error = error {
                AppLogger.shared.error("Rewarded load error: \(error.localizedDescription)")
                self.rewardedAd = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                    self?.loadRewardedAd()
                }
                return
            }
            guard let ad = ad else {
                self.rewardedAd = nil
                return
            }
            ad.fullScreenContentDelegate = self
            self.rewardedAd = ad
            AppLogger.shared.log("Rewarded ad loaded successfully")
            if let onEarned = self.rewardedOnEarned, let onClose = self.rewardedOnClose {
                self.rewardedOnEarned = nil
                self.rewardedOnClose = nil
                self.showLoadedRewarded(onRewardEarned: onEarned, onClose: onClose)
            }
        }
    }

    func showRewarded(onRewardEarned: @escaping (Int) -> Void, onClose: @escaping () -> Void) {
        if let rewarded = rewardedAd {
            showLoadedRewarded(onRewardEarned: onRewardEarned, onClose: onClose)
        } else {
            AppLogger.shared.log("Rewarded ad not ready, waiting for load...")
            rewardedOnEarned = onRewardEarned
            rewardedOnClose = onClose
            loadRewardedAd()
        }
    }

    private func showLoadedRewarded(onRewardEarned: @escaping (Int) -> Void, onClose: @escaping () -> Void) {
        guard let rootVC = getRootViewController(), let rewarded = rewardedAd else {
            onClose()
            return
        }
        rewarded.present(from: rootVC) {
            onRewardEarned(rewarded.adReward.amount.intValue)
        }
        self.rewardedAd = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.loadRewardedAd()
        }
        onClose()
    }

    // MARK: - Rewarded Prompt Timer
    func startRewardedPromptTimer() {
        stopRewardedPromptTimer()
        rewardedPromptTimer = Timer.scheduledTimer(withTimeInterval: rewardedPromptInterval, repeats: true) { [weak self] _ in
            self?.triggerRewardedPrompt()
        }
        AppLogger.shared.log("Rewarded prompt timer started (3 minute interval)")
    }

    func stopRewardedPromptTimer() {
        rewardedPromptTimer?.invalidate()
        rewardedPromptTimer = nil
    }

    private func triggerRewardedPrompt() {
        guard !isRewardedPromptVisible else { return }
        guard rewardedAd != nil else {
            AppLogger.shared.log("Rewarded prompt: no ad loaded, attempting reload")
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
            AppLogger.shared.log("Rewarded prompt presented")
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
        if ad === interstitialAd {
            loadInterstitialAd()
        } else if ad === returningInterstitialAd {
            loadReturningInterstitialAd()
        }
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        AppLogger.shared.error("Ad failed to present: \(error.localizedDescription)")
        if ad === interstitialAd {
            interstitialAd = nil
            loadInterstitialAd()
        } else if ad === returningInterstitialAd {
            returningInterstitialAd = nil
            loadReturningInterstitialAd()
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
