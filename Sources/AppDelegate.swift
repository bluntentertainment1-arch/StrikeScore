import UIKit
import GoogleMobileAds
import AppTrackingTransparency

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        MobileAds.shared.start()
        AppLogger.shared.log("App launched - AdMob initialized")
        
        // Check ATT status on launch
        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            AppLogger.shared.log("ATT status on launch: \(status.rawValue)")
        }
        
        return true
    }
}
