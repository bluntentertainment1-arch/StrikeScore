import GoogleMobileAds

class AdMobManager {
    static let shared = AdMobManager()

    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716" // Test ID
    static let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313" // Test ID
    static let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910" // Test ID

    private var rewardedAd: RewardedAd?

    func loadRewardedAd() {
        let request = Request()
        RewardedAd.load(with: AdMobManager.rewardedAdUnitID, request: request) { ad, error in
            if let error = error {
                AppLogger.shared.error("Failed to load rewarded ad: \(error.localizedDescription)")
                return
            }
            self.rewardedAd = ad
        }
    }

    func showRewardedAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard let rewardedAd = rewardedAd else {
            completion(false)
            return
        }
        rewardedAd.present(from: viewController) {
            completion(true)
        }
    }
}
