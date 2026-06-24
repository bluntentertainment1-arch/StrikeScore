import Foundation
import GoogleMobileAds

class GDPRConsentManager {
    static let shared = GDPRConsentManager()

    private let consentKey = "gdpr_consent_given"
    private let adsConsentKey = "gdpr_personalized_ads_allowed"

    /// Returns true if the user has completed the onboarding choice at least once
    var hasConsentGiven: Bool {
        UserDefaults.standard.bool(forKey: consentKey)
    }

    /// Sets up and stores the granular user configurations
    func saveUserPreferences(allowAnalytics: Bool, allowPersonalizedAds: Bool) {
        UserDefaults.standard.set(true, forKey: consentKey)
        UserDefaults.standard.set(allowPersonalizedAds, forKey: adsConsentKey)
        
        // Pass preferences directly into the global Google Mobile Ads settings
        updateAdMobConsent(personalized: allowPersonalizedAds)
    }

    /// Instructs the AdMob engine exactly how to format tracking behaviors
    func updateAdMobConsent(personalized: Bool) {
        let requestConfiguration = MobileAds.sharedInstance.requestConfiguration
        
        if personalized {
            // Clears restrictions for standard delivery
            requestConfiguration.underAgeOfConsent = false
        } else {
            // Force strict non-personalized delivery tags for compliance
            requestConfiguration.underAgeOfConsent = true
        }
    }
}
