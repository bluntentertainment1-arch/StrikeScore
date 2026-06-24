import GoogleMobileAds
import UIKit

class AdMobManager: NSObject {
    static let shared = AdMobManager()

    // Official Google AdMob test IDs[span_2](start_span)[span_2](end_span)
    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716[span_3](start_span)"[span_3](end_span)
    static let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313[span_4](start_span)"[span_4](end_span)
    static let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910[span_5](start_span)"[span_5](end_span)

    private var interstitialAd: InterstitialAd?
    private var rewardedAd: RewardedAd?[span_6](start_span)[span_6](end_span)

    private override init() {
        super.init()
    }

    /// Preloads all ad units concurrently on app initialization
    func loadAllAds() {
        loadInterstitialAd()
        loadRewardedAd()
    }

    // MARK: - Interstitial Ad Engine
    func loadInterstitialAd() {
        let request = Request()[span_7](start_span)[span_7](end_span)[span_8](start_span)[span_8](end_span)
        InterstitialAd.load(with: AdMobManager.interstitialAdUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                AppLogger.shared.error("Interstitial Ad missing or failed to preload: \(error.localizedDescription)")[span_9](start_span)[span_9](end_span)
                return
            }
            self?.interstitialAd = ad
        }
    }

    func showInterstitial(completion: @escaping () -> Void) {
        guard let rootVC = getRootViewController() else {
            completion()
            return
        }
        
        if let interstitial = interstitialAd {
            interstitial.present(from: rootVC)
            self.interstitialAd = nil // Flush used instance
            loadInterstitialAd()      // Cycle background refresh
            completion()
        } else {
            // Fail safely and instantly execute app behavior if background load isn't ready
            completion()
        }
    }

    // MARK: - Rewarded Ad Engine
    func loadRewardedAd() {
        let request = Request()[span_10](start_span)[span_10](end_span)[span_11](start_span)[span_11](end_span)
        RewardedAd.load(with: AdMobManager.rewardedAdUnitID, request: request) { [weak self] ad, error in[span_12](start_span)[span_12](end_span)
            if let error = error {[span_13](start_span)[span_13](end_span)
                AppLogger.shared.error("Rewarded Ad missing or failed to preload: \(error.localizedDescription)")[span_14](start_span)[span_14](end_span)
                return[span_15](start_span)[span_15](end_span)
            }[span_16](start_span)[span_16](end_span)
            self?.rewardedAd = ad[span_17](start_span)[span_17](end_span)
        }[span_18](start_span)[span_18](end_span)
    }

    func showRewarded(onRewardEarned: @escaping (Int) -> Void, onClose: @escaping () -> Void) {
        guard let rootVC = getRootViewController(), let rewarded = rewardedAd else {[span_19](start_span)[span_19](end_span)
            onClose()
            return
        }
        
        rewarded.present(from: rootVC) {[span_20](start_span)[span_20](end_span)
            let reward = rewarded.adReward
            onRewardEarned(reward.amount.intValue)
        }
        
        self.rewardedAd = nil
        loadRewardedAd() // Preload next instance instantly
    }

    // MARK: - Modern Safe Window Resolution Context Lookups
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        return rootVC
    }
}
