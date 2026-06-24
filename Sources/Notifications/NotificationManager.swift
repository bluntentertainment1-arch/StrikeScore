import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            AppLogger.shared.log("Notification permission: \(granted)")
        }
    }

    // Accepting Match models directly so you do not need to manually parse strings upstream
    func scheduleMatchReminder(for match: Match) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        
        // Extract a valid system Date sequence out of the model string property
        guard let matchDate = formatter.date(from: match.utcDate) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Match Starting Soon!"
        content.body = "\(match.homeTeam.name) vs \(match.awayTeam.name) kicks off in 15 minutes"
        content.sound = .default

        // Schedules local notifications exactly 15 minutes prior to game kick-off
        let triggerDate = Calendar.current.date(byAdding: .minute, value: -15, to: matchDate)!
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: "match-\(match.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
