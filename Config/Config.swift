import Foundation

enum AppConfig {
    static let appName = AppConstants.appName
    static let companyName = AppConstants.companyName
    static let copyright = AppConstants.copyright
    static let contactEmail = AppConstants.contactEmail
    static let appVersion = AppConstants.appVersion

    static let footballDataBaseURL = AppConstants.footballDataBaseURL
    static let defaultCompetition = AppConstants.defaultCompetition

    static let excelFeaturedURL = AppConstants.excelFeaturedURL
    static let excelEditorialURL = AppConstants.excelEditorialURL
    static let excelConfigURL = AppConstants.excelConfigURL

    static let apiPollInterval: TimeInterval = AppConstants.apiPollInterval
    static let excelRefreshInterval: TimeInterval = AppConstants.excelRefreshInterval
}
