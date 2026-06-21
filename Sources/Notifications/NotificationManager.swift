import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            AppLogger.shared.log("Notification permission: \(granted)")
        }
    }

    func scheduleMatchReminder(matchId: Int, matchTitle: String, date: Date) {
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
}
