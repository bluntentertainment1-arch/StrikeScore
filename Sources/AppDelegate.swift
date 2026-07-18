import UIKit
import GoogleMobileAds
import AppTrackingTransparency
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // 1. Initialize Firebase 
        FirebaseApp.configure()
        AppLogger.shared.log("App launched - Firebase Analytics initialized")

        // 2. Configure AdMob — wait for the SDK's own completion callback
        // before requesting any ads. Firing preloadAllAds() immediately
        // after calling start() (the old code) doesn't wait for the SDK to
        // actually finish initializing, so the very first ad requests after
        // a cold launch would routinely fail. Each failure then walks the
        // exponential backoff ladder (15s, 30s, 60s...), which is exactly
        // what produced the 3-5 minute delay before the first interstitial
        // became available.
        MobileAds.shared.start { _ in
            AppLogger.shared.log("AdMob SDK fully initialized")
            AdMobManager.shared.preloadAllAds()
        }
        AppLogger.shared.log("App launched - AdMob initializing")

        // 3. Check ATT status on launch
        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            AppLogger.shared.log("ATT status on launch: \(status.rawValue)")
        }

        return true
    }

    // MARK: - Portrait Orientation Lock (app-wide)
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
}
