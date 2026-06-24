import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            AppLogger.shared.log("Notification permission: \(granted)")
        }
    }

    func scheduleMatchReminder(matchId: String, matchTitle: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Match Starting Soon!"
        content.body = "\(matchTitle) kicks off in 15 minutes"
        content.sound = .default

        let triggerDate = Calendar.current.date(byAdding: .minute, value: -15, to: date)!
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: "match-\(matchId)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // ✅ FIXED: Restored missing trending news & daily editorial push routing method
    func scheduleDailyEditorialNotifications(articles: [EditorialItem]) {
        AppLogger.shared.log("Scheduling notification updates for \(articles.count) editorial news articles.")
        
        let content = UNMutableNotificationContent()
        content.title = "Trending Sports News"
        content.body = "Check out the latest trending match updates and analysis!"
        content.sound = .default

        // Fires a daily notification reminder
        var components = DateComponents()
        components.hour = 10 // 10:00 AM
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-editorial-news", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
