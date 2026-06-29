import SwiftUI
import GoogleMobileAds
import UIKit

class AdMobManager: NSObject, FullScreenContentDelegate {
    static let shared = AdMobManager()

    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    static let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    static let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    static let squareBannerAdUnitID = "ca-app-pub-3940256099942544/2435281174"

    // MARK: - Separate Ad Instances
    private var fixtureInterstitialAd: InterstitialAd?
    private var articleInterstitialAd: InterstitialAd?
    private var linkInterstitialAd: InterstitialAd?
    private var returningInterstitialAd: InterstitialAd?
    private var rewardedAd: RewardedAd?

    // MARK: - Pending Completions (execute after ad dismisses)
    private var pendingInterstitialCompletion: (() -> Void)?
    private var pendingRewardedClose: (() -> Void)?

    // MARK: - Independent Cooldowns
    private var lastFixtureInterstitialTime: Date?
    private var lastArticleInterstitialTime: Date?
    private var lastLinkInterstitialTime: Date?
    private var lastReturningAdTime: Date?

    private let fixtureCooldown: TimeInterval = 20
    private let articleCooldown: TimeInterval = 20
    private let linkCooldown: TimeInterval = 60
    private let returningAdCooldown: TimeInterval = 20

    // MARK: - Tap Tracking
    private var fixtureTapCount = 0
    private var articleTapIndices: Set<Int> = []

    // MARK: - Rewarded Prompt Timer
    private var rewardedPromptTimer: Timer?
    private var isRewardedPromptVisible = false
    private let rewardedPromptInterval: TimeInterval = 180 // 3 minutes

    // MARK: - Returning Ad Tracking
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
        AppLogger.shared.log("Preloading all ads...")
        loadFixtureInterstitial()
        loadArticleInterstitial()
        loadLinkInterstitial()
        loadReturningInterstitialAd()
        loadRewardedAd()
    }

    // MARK: - Fixture Interstitial
    private func loadFixtureInterstitial(retryCount: Int = 0) {
        guard fixtureInterstitialAd == nil else { return }
        let request = Request()
        InterstitialAd.load(with: AdMobManager.interstitialAdUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            if let error = error {
                AppLogger.shared.error("Fixture interstitial load error: \(error.localizedDescription)")
                self.fixtureInterstitialAd = nil
                let delay = min(5.0 * pow(2.0, Double(retryCount)), 30.0)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.loadFixtureInterstitial(retryCount: retryCount + 1)
                }
                return
            }
            guard let ad = ad else {
                AppLogger.shared.error("Fixture interstitial load returned nil ad")
                self.fixtureInterstitialAd = nil
                return
            }
            ad.fullScreenContentDelegate = self
            self.fixtureInterstitialAd = ad
            AppLogger.shared.log("Fixture interstitial LOADED and READY")
        }
    }

    func showFixtureInterstitialIfAllowed(completion: @escaping () -> Void) {
        AppLogger.shared.log("showFixtureInterstitialIfAllowed called, ad ready: \(fixtureInterstitialAd != nil)")
        if let lastTime = lastFixtureInterstitialTime {
            guard Date().timeIntervalSince(lastTime) >= fixtureCooldown else {
                AppLogger.shared.log("Fixture interstitial on cooldown")
                completion()
                return
            }
        }
        guard let rootVC = getRootViewController(), let ad = fixtureInterstitialAd else {
            AppLogger.shared.log("Fixture interstitial NOT ready, loading now...")
            loadFixtureInterstitial()
            completion()
            return
        }
        // FIX #1: Store completion, execute after ad dismisses
        pendingInterstitialCompletion = completion
        ad.present(from: rootVC)
        fixtureInterstitialAd = nil
        lastFixtureInterstitialTime = Date()
        // FIX #8: Delay reload by 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.loadFixtureInterstitial()
        }
    }

    // MARK: - Article Interstitial
    private func loadArticleInterstitial(retryCount: Int = 0) {
        guard articleInterstitialAd == nil else { return }
        let request = Request()
        InterstitialAd.load(with: AdMobManager.interstitialAdUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            if let error = error {
                AppLogger.shared.error("Article interstitial load error: \(error.localizedDescription)")
                self.articleInterstitialAd = nil
                let delay = min(5.0 * pow(2.0, Double(retryCount)), 30.0)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.loadArticleInterstitial(retryCount: retryCount + 1)
                }
                return
            }
            guard let ad = ad else {
                AppLogger.shared.error("Article interstitial load returned nil ad")
                self.articleInterstitialAd = nil
                return
            }
            ad.fullScreenContentDelegate = self
            self.articleInterstitialAd = ad
            AppLogger.shared.log("Article interstitial LOADED and READY")
        }
    }

    func showArticleInterstitialIfAllowed(completion: @escaping () -> Void) {
        AppLogger.shared.log("showArticleInterstitialIfAllowed called, ad ready: \(articleInterstitialAd != nil)")
        if let lastTime = lastArticleInterstitialTime {
            guard Date().timeIntervalSince(lastTime) >= articleCooldown else {
                AppLogger.shared.log("Article interstitial on cooldown")
                completion()
                return
            }
        }
        guard let rootVC = getRootViewController(), let ad = articleInterstitialAd else {
            AppLogger.shared.log("Article interstitial NOT ready, loading now...")
            loadArticleInterstitial()
            completion()
            return
        }
        pendingInterstitialCompletion = completion
        ad.present(from: rootVC)
        articleInterstitialAd = nil
        lastArticleInterstitialTime = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.loadArticleInterstitial()
        }
    }

    // MARK: - Link Interstitial (EVERY tap)
    private func loadLinkInterstitial(retryCount: Int = 0) {
        guard linkInterstitialAd == nil else { return }
        let request = Request()
        InterstitialAd.load(with: AdMobManager.interstitialAdUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            if let error = error {
                AppLogger.shared.error("Link interstitial load error: \(error.localizedDescription)")
                self.linkInterstitialAd = nil
                let delay = min(5.0 * pow(2.0, Double(retryCount)), 30.0)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.loadLinkInterstitial(retryCount: retryCount + 1)
                }
                return
            }
            guard let ad = ad else {
                AppLogger.shared.error("Link interstitial load returned nil ad")
                self.linkInterstitialAd = nil
                return
            }
            ad.fullScreenContentDelegate = self
            self.linkInterstitialAd = ad
            AppLogger.shared.log("Link interstitial LOADED and READY")
        }
    }

    func showLinkInterstitialIfAllowed(completion: @escaping () -> Void) {
        AppLogger.shared.log("showLinkInterstitialIfAllowed called, ad ready: \(linkInterstitialAd != nil)")
        if let lastTime = lastLinkInterstitialTime {
            guard Date().timeIntervalSince(lastTime) >= linkCooldown else {
                AppLogger.shared.log("Link interstitial on cooldown")
                completion()
                return
            }
        }
        guard let rootVC = getRootViewController(), let ad = linkInterstitialAd else {
            AppLogger.shared.log("Link interstitial NOT ready, loading now...")
            loadLinkInterstitial()
            completion()
            return
        }
        // FIX #2: Store completion, execute after ad dismisses
        pendingInterstitialCompletion = completion
        ad.present(from: rootVC)
        linkInterstitialAd = nil
        lastLinkInterstitialTime = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.loadLinkInterstitial()
        }
    }

    // MARK: - Returning Interstitial
    func loadReturningInterstitialAd(retryCount: Int = 0) {
        guard returningInterstitialAd == nil else { return }
        let request = Request()
        InterstitialAd.load(with: AdMobManager.interstitialAdUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            if let error = error {
                AppLogger.shared.error("Returning interstitial load error: \(error.localizedDescription)")
                self.returningInterstitialAd = nil
                let delay = min(5.0 * pow(2.0, Double(retryCount)), 30.0)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.loadReturningInterstitialAd(retryCount: retryCount + 1)
                }
                return
            }
            guard let ad = ad else {
                AppLogger.shared.error("Returning interstitial load returned nil ad")
                self.returningInterstitialAd = nil
                return
            }
            ad.fullScreenContentDelegate = self
            self.returningInterstitialAd = ad
            AppLogger.shared.log("Returning interstitial LOADED and READY")
        }
    }

    func showReturningAdIfAllowed() {
        AppLogger.shared.log("showReturningAdIfAllowed called, ad ready: \(returningInterstitialAd != nil)")
        if let lastTime = lastReturningAdTime {
            guard Date().timeIntervalSince(lastTime) >= returningAdCooldown else {
                AppLogger.shared.log("Returning interstitial on cooldown")
                if returningInterstitialAd == nil {
                    loadReturningInterstitialAd()
                }
                return
            }
        }
        guard let rootVC = getRootViewController(), let ad = returningInterstitialAd else {
            AppLogger.shared.log("Returning interstitial NOT ready, loading now...")
            loadReturningInterstitialAd()
            return
        }
        ad.present(from: rootVC)
        returningInterstitialAd = nil
        lastReturningAdTime = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.loadReturningInterstitialAd()
        }
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

    func trackLinkTap() {
        // No-op - links show ad on every tap
    }

    // MARK: - Rewarded Ad
    func loadRewardedAd(retryCount: Int = 0) {
        guard rewardedAd == nil else { return }
        let request = Request()
        RewardedAd.load(with: AdMobManager.rewardedAdUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            if let error = error {
                AppLogger.shared.error("Rewarded load error: \(error.localizedDescription)")
                self.rewardedAd = nil
                let delay = min(5.0 * pow(2.0, Double(retryCount)), 30.0)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.loadRewardedAd(retryCount: retryCount + 1)
                }
                return
            }
            guard let ad = ad else {
                AppLogger.shared.error("Rewarded load returned nil ad")
                self.rewardedAd = nil
                return
            }
            ad.fullScreenContentDelegate = self
            self.rewardedAd = ad
            AppLogger.shared.log("Rewarded ad LOADED and READY")
        }
    }

    func showRewarded(onRewardEarned: @escaping (Int) -> Void, onClose: @escaping () -> Void) {
        AppLogger.shared.log("showRewarded called, ad ready: \(rewardedAd != nil)")
        guard let rootVC = getRootViewController(), let rewarded = rewardedAd else {
            AppLogger.shared.log("Rewarded ad NOT ready, loading now...")
            loadRewardedAd()
            onClose()
            return
        }
        // FIX #5: Store onClose, execute after ad dismisses
        pendingRewardedClose = onClose
        rewarded.present(from: rootVC) {
            onRewardEarned(rewarded.adReward.amount.intValue)
        }
        self.rewardedAd = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.loadRewardedAd()
        }
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
        AppLogger.shared.log("triggerRewardedPrompt called, ad ready: \(rewardedAd != nil), visible: \(isRewardedPromptVisible)")
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
            AppLogger.shared.log("Rewarded prompt PRESENTED")
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
        AppLogger.shared.log("Ad dismissed")
        // FIX #1, #2: Execute pending completion AFTER ad dismisses
        pendingInterstitialCompletion?()
        pendingInterstitialCompletion = nil
        // FIX #5: Execute pending rewarded close AFTER ad dismisses
        pendingRewardedClose?()
        pendingRewardedClose = nil
        // Reload all ads
        loadFixtureInterstitial()
        loadArticleInterstitial()
        loadLinkInterstitial()
        loadReturningInterstitialAd()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        AppLogger.shared.error("Ad failed to present: \(error.localizedDescription)")
        // Clear pending completions on failure so UI doesn't hang
        pendingInterstitialCompletion?()
        pendingInterstitialCompletion = nil
        pendingRewardedClose?()
        pendingRewardedClose = nil
        loadFixtureInterstitial()
        loadArticleInterstitial()
        loadLinkInterstitial()
        loadReturningInterstitialAd()
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
