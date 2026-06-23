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
        
        // 2. Configure AdMob
        MobileAds.shared.start() 
        AppLogger.shared.log("App launched - AdMob initialized")
        
        // 3. Check ATT status on launch
        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            AppLogger.shared.log("ATT status on launch: \(status.rawValue)")
        }
        
        return true
    }
}
