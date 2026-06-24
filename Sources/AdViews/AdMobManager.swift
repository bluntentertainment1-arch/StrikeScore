import GoogleMobileAds
import UIKit

class AdMobManager: NSObject {
    static let shared = AdMobManager()

    // Official Google AdMob global validation production-safe testing keys
    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    static let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313" 
    static let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"

    private var interstitialAd: GADInterstitialAd?
    private var rewardedAd: GADRewardedAd?

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
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: AdMobManager.interstitialAdUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                AppLogger.shared.error("Interstitial Ad missing or failed to preload: \(error.localizedDescription)")
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
            interstitial.present(fromRootViewController: rootVC)
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
        let request = GADRequest()
        GADRewardedAd.load(withAdUnitID: AdMobManager.rewardedAdUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                AppLogger.shared.error("Rewarded Ad missing or failed to preload: \(error.localizedDescription)")
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
        
        rewarded.present(fromRootViewController: rootVC) {
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
