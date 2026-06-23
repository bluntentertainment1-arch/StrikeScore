import UIKit
import GoogleMobileAds
import AppTrackingTransparency
import FirebaseCore // 1. Import the Firebase module

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 2. Initialize Firebase before your other services configure
        FirebaseApp.configure()
        AppLogger.shared.log("App launched - Firebase Analytics initialized")[span_4](start_span)[span_4](end_span)[span_5](start_span)[span_5](end_span)
        
        MobileAds.shared.start() // Keep your existing setups untouched[span_6](start_span)[span_6](end_span)
        AppLogger.shared.log("App launched - AdMob initialized")[span_7](start_span)[span_7](end_span)[span_8](start_span)[span_8](end_span)
        
        // Check ATT status on launch
        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus[span_9](start_span)[span_9](end_span)
            AppLogger.shared.log("ATT status on launch: \(status.rawValue)")[span_10](start_span)[span_10](end_span)[span_11](start_span)[span_11](end_span)
        }
        
        return true[span_12](start_span)[span_12](end_span)
    }
}
