import Foundation

enum AppConstants {
    static let appName = "StrikeScore"
    static let companyName = "kidblunt"
    static let copyright = "© 2026 kidblunt. All rights reserved."
    static let contactEmail = "bluntentertainment1@gmail.com"
    static let appVersion = "1.0.0"

    static let footballDataBaseURL = "https://api.football-data.org/v4"
    static let defaultCompetition = "WC"

    static let excelFeaturedURL = "https://docs.google.com/spreadsheets/d/e/2PACX-1vTmtdMDK95ZVLkq9pmki8FgNmD2_PeeBzUT5QHrXO6LyyAzddBVrzThp1RmKfo8g-wW9Cw-aQFRL_rI/pub?gid=792685785&single=true&output=csv"
    static let excelEditorialURL = "https://docs.google.com/spreadsheets/d/e/2PACX-1vTmtdMDK95ZVLkq9pmki8FgNmD2_PeeBzUT5QHrXO6LyyAzddBVrzThp1RmKfo8g-wW9Cw-aQFRL_rI/pub?gid=600659522&single=true&output=csv"
    static let excelConfigURL = "https://docs.google.com/spreadsheets/d/e/2PACX-1vTmtdMDK95ZVLkq9pmki8FgNmD2_PeeBzUT5QHrXO6LyyAzddBVrzThp1RmKfo8g-wW9Cw-aQFRL_rI/pub?gid=1758911275&single=true&output=csv"

    static let apiPollInterval: TimeInterval = 30
    static let excelRefreshInterval: TimeInterval = 300
}
