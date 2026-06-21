import SwiftUI

enum ThemeManager {
    static let primaryColor = Color.green
    static let accentColor = Color.orange
    static let backgroundColor = Color(.systemBackground)
    static let cardBackground = Color(.systemGray6)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary

    static func applyAppearance() {
        UINavigationBar.appearance().tintColor = UIColor(primaryColor)
        UITabBar.appearance().tintColor = UIColor(primaryColor)
    }
}
