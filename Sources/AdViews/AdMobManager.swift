import SwiftUI
import GoogleMobileAds
import UIKit

class AdMobManager: NSObject, UIAdaptivePresentationControllerDelegate {
    static let shared = AdMobManager()

    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    static let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    static let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    static let squareBannerAdUnitID = "ca-app-pub-3940256099942544/2435281174"

    private var interstitialAd: InterstitialAd?
    private var rewardedAd: RewardedAd?

    private var lastInterstitialShowTime: Date?
    private var hasShownFirstInterstitialThisSession = false
    private let interstitialCooldown: TimeInterval = 240

    // MARK: - Tap Tracking
    private var fixtureTapCount = 0
    private var articleTapIndices: Set<Int> = []
    private var linkTapCount = 0

    // MARK: - Rewarded Prompt
    private var rewardedPromptTimer: Timer?
    private var isRewardedPromptVisible = false
    private let rewardedPromptInterval: TimeInterval = 300

    private override init() {
        super.init()
    }

    func loadAllAds() {
        loadInterstitialAd()
        loadRewardedAd()
    }

    // MARK: - Interstitial
    func loadInterstitialAd() {
        let request = Request()
        InterstitialAd.load(with: AdMobManager.interstitialAdUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                AppLogger.shared.error("Interstitial load error: \(error.localizedDescription)")
                return
            }
            self?.interstitialAd = ad
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
            loadInterstitialAd()
            completion()
        } else {
            completion()
        }
    }

    func showInterstitialIfAllowed(completion: @escaping () -> Void) {
        if canShowInterstitial {
            showInterstitial(completion: completion)
        } else {
            completion()
        }
    }

    // MARK: - Conditional Triggers
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

    // MARK: - Rewarded
    func loadRewardedAd() {
        let request = Request()
        RewardedAd.load(with: AdMobManager.rewardedAdUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                AppLogger.shared.error("Rewarded load error: \(error.localizedDescription)")
                return
            }
            self?.rewardedAd = ad
        }
    }

    func showRewarded(onRewardEarned: @escaping (Int) -> Void, onClose: @escaping () -> Void) {
        guard let rootVC = getRootViewController(), let rewarded = rewardedAd else {
            onClose()
            return
        }
        rewarded.present(from: rootVC) {
            onRewardEarned(rewarded.adReward.amount.intValue)
        }
        self.rewardedAd = nil
        loadRewardedAd()
        onClose()
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

    // MARK: - Window Lookup
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        return rootVC
    }
}
