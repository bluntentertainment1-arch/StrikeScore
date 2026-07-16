import SwiftUI
import GoogleMobileAds
import UIKit

class AdMobManager: NSObject, FullScreenContentDelegate {
    static let shared = AdMobManager()

    static let bannerAdUnitID = "ca-app-pub-1819215492028258/9538984219"
    static let rewardedAdUnitID = "ca-app-pub-1819215492028258/9042697753"
    static let interstitialAdUnitID = "ca-app-pub-1819215492028258/7538044399"
    static let nativeAdUnitID = "ca-app-pub-1819215492028258/9196771651"

    // MARK: - Single Shared Interstitial Instance
    // Previously each trigger point (fixture/article/link/close/returning) held its
    // own InterstitialAd and loaded it independently — all five pointed at the SAME
    // ad unit ID and were preloaded simultaneously, which is what was tripping
    // AdMob's "too many recently failed requests" throttling. There is exactly one
    // interstitial ad unit, so there should be exactly one loaded instance at a time.
    // The `closeInterstitialAd` slot was also dead code: nothing in the app ever
    // called showCloseInterstitialIfAllowed(), so it was just extra load/retry
    // traffic for no reason. It has been removed.
    private var interstitialAd: InterstitialAd?
    private var isLoadingInterstitial = false
    private var interstitialRetryCount = 0
    private var rewardedAd: RewardedAd?
    private var isLoadingRewarded = false
    private var rewardedRetryCount = 0

    // MARK: - Pending Completions (execute after ad dismisses)
    private var pendingInterstitialCompletion: (() -> Void)?
    private var pendingRewardedClose: (() -> Void)?

    // MARK: - Independent Cooldowns (per trigger point, unchanged)
    private var lastFixtureInterstitialTime: Date?
    private var lastArticleInterstitialTime: Date?
    private var lastLinkInterstitialTime: Date?
    private var lastReturningAdTime: Date?

    private let fixtureCooldown: TimeInterval = 20
    private let articleCooldown: TimeInterval = 20
    private let linkCooldown: TimeInterval = 0                // FIX #1: Remove link cooldown
    private let returningAdCooldown: TimeInterval = 20

    // Exponential backoff for ad load retries: 15s, 30s, 60s, 120s, capped at 300s.
    // (Was 5/10/20/30s, which was aggressive enough to contribute to throttling.)
    private func retryDelay(for retryCount: Int) -> TimeInterval {
        min(15.0 * pow(2.0, Double(retryCount)), 300.0)
    }

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
        loadInterstitial()
        loadRewardedAd()
    }

    // MARK: - Single Interstitial Loader
    // One instance, one ad unit, one in-flight request at a time. `isLoadingInterstitial`
    // prevents two near-simultaneous callers (e.g. app launch + a view appearing) from
    // both seeing `interstitialAd == nil` and firing duplicate requests.
    private func loadInterstitial() {
        guard interstitialAd == nil, !isLoadingInterstitial else { return }
        isLoadingInterstitial = true
        let request = Request()
        InterstitialAd.load(with: AdMobManager.interstitialAdUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            self.isLoadingInterstitial = false
            if let error = error {
                AppLogger.shared.error("Interstitial load error: \(error.localizedDescription)")
                self.interstitialAd = nil
                let delay = self.retryDelay(for: self.interstitialRetryCount)
                self.interstitialRetryCount += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.loadInterstitial()
                }
                return
            }
            guard let ad = ad else {
                AppLogger.shared.error("Interstitial load returned nil ad")
                self.interstitialAd = nil
                return
            }
            self.interstitialRetryCount = 0
            ad.fullScreenContentDelegate = self
            self.interstitialAd = ad
            AppLogger.shared.log("Interstitial LOADED and READY")
        }
    }

    /// Shared present routine used by every trigger point. `cooldown`/`lastTime` are
    /// passed in so each call site keeps its own independent cooldown behavior even
    /// though they all now share one underlying ad instance.
    private func presentInterstitialIfAllowed(
        lastTime: Date?,
        cooldown: TimeInterval,
        recordTime: (Date) -> Void,
        completion: (() -> Void)?
    ) {
        if let lastTime = lastTime {
            guard Date().timeIntervalSince(lastTime) >= cooldown else {
                AppLogger.shared.log("Interstitial on cooldown for this trigger")
                completion?()
                return
            }
        }
        guard let rootVC = getRootViewController(), let ad = interstitialAd else {
            AppLogger.shared.log("Interstitial NOT ready, loading now...")
            loadInterstitial()
            completion?()
            return
        }
        pendingInterstitialCompletion = completion
        ad.present(from: rootVC)
        interstitialAd = nil
        recordTime(Date())
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.loadInterstitial()
        }
    }

    func showFixtureInterstitialIfAllowed(completion: @escaping () -> Void) {
        AppLogger.shared.log("showFixtureInterstitialIfAllowed called, ad ready: \(interstitialAd != nil)")
        presentInterstitialIfAllowed(
            lastTime: lastFixtureInterstitialTime,
            cooldown: fixtureCooldown,
            recordTime: { [weak self] in self?.lastFixtureInterstitialTime = $0 },
            completion: completion
        )
    }

    func showArticleInterstitialIfAllowed(completion: @escaping () -> Void) {
        AppLogger.shared.log("showArticleInterstitialIfAllowed called, ad ready: \(interstitialAd != nil)")
        presentInterstitialIfAllowed(
            lastTime: lastArticleInterstitialTime,
            cooldown: articleCooldown,
            recordTime: { [weak self] in self?.lastArticleInterstitialTime = $0 },
            completion: completion
        )
    }

    func showLinkInterstitialIfAllowed(completion: @escaping () -> Void) {
        AppLogger.shared.log("showLinkInterstitialIfAllowed called, ad ready: \(interstitialAd != nil)")
        presentInterstitialIfAllowed(
            lastTime: lastLinkInterstitialTime,
            cooldown: linkCooldown,
            recordTime: { [weak self] in self?.lastLinkInterstitialTime = $0 },
            completion: completion
        )
    }

    func showReturningAdIfAllowed() {
        AppLogger.shared.log("showReturningAdIfAllowed called, ad ready: \(interstitialAd != nil)")
        presentInterstitialIfAllowed(
            lastTime: lastReturningAdTime,
            cooldown: returningAdCooldown,
            recordTime: { [weak self] in self?.lastReturningAdTime = $0 },
            completion: nil
        )
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
    func loadRewardedAd() {
        guard rewardedAd == nil, !isLoadingRewarded else { return }
        isLoadingRewarded = true
        let request = Request()
        RewardedAd.load(with: AdMobManager.rewardedAdUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            self.isLoadingRewarded = false
            if let error = error {
                AppLogger.shared.error("Rewarded load error: \(error.localizedDescription)")
                self.rewardedAd = nil
                let delay = self.retryDelay(for: self.rewardedRetryCount)
                self.rewardedRetryCount += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.loadRewardedAd()
                }
                return
            }
            guard let ad = ad else {
                AppLogger.shared.error("Rewarded load returned nil ad")
                self.rewardedAd = nil
                return
            }
            self.rewardedRetryCount = 0
            ad.fullScreenContentDelegate = self
            self.rewardedAd = ad
            AppLogger.shared.log("Rewarded ad loaded")
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
        AppLogger.shared.log("Rewarded timer started")
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

            // FIX #5: Block prompt if another modal is already presented
            guard rootVC.presentedViewController == nil else {
                AppLogger.shared.log("Rewarded prompt blocked by modal")
                return
            }

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
        AppLogger.shared.log("Ad dismissed")
        pendingInterstitialCompletion?()
        pendingInterstitialCompletion = nil
        pendingRewardedClose?()
        pendingRewardedClose = nil
        loadInterstitial()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        AppLogger.shared.error("Ad failed to present: \(error.localizedDescription)")
        pendingInterstitialCompletion?()
        pendingInterstitialCompletion = nil
        pendingRewardedClose?()
        pendingRewardedClose = nil
        loadInterstitial()
    }

    // MARK: - Window Lookup (FIX #6: Walk to top presented controller)
    private func getRootViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else {
            return nil
        }
        var current = root
        while let presented = current.presentedViewController {
            current = presented
        }
        return current
    }
}
