import Foundation

class GDPRConsentManager {
    static let shared = GDPRConsentManager()

    private let consentKey = "gdpr_consent_given"

    var hasConsent: Bool {
        UserDefaults.standard.bool(forKey: consentKey)
    }

    func giveConsent() {
        UserDefaults.standard.set(true, forKey: consentKey)
    }

    func revokeConsent() {
        UserDefaults.standard.set(false, forKey: consentKey)
    }

    func resetConsent() {
        UserDefaults.standard.removeObject(forKey: consentKey)
    }
}
