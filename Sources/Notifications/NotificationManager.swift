import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    // Key used to track sent article IDs locally so they are never repeated
    private let postedHistoryKey = "sent_editorial_headlines_history"

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            AppLogger.shared.log("Notification permission: \(granted)")
        }
    }

    /// Schedules fresh daily headline reminders across 9am, 1pm, and 7pm slots matching available news pools
    func scheduleDailyEditorialNotifications(articles: [EditorialItem]) {
        // Clear out any old pending headline requests to start fresh
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["headline-9am", "headline-1pm", "headline-7pm"])
        
        let activeArticles = articles.filter { $0.active }
        guard !activeArticles.isEmpty else { return }
        
        var sentIDs = UserDefaults.standard.stringArray(forKey: postedHistoryKey) ?? []
        
        // Find fresh news stories that haven't been posted yet
        var availablePool = activeArticles.filter { !sentIDs.contains($0.id) }
        
        // Target daily intervals: 9 AM, 1 PM, 7 PM
        let targetHours = [9, 13, 19]
        let slotIdentifiers = ["headline-9am", "headline-1pm", "headline-7pm"]
        
        for index in 0..<targetHours.count {
            // IF all headlines have been posted, stop scheduling until new articles drop
            guard !availablePool.isEmpty else {
                AppLogger.shared.log("⚠️ Notification warning: Out of fresh headlines. Pausing schedules.")
                break
            }
            
            // Extract the next fresh story from the top of the pool
            let targetArticle = availablePool.removeFirst()
            sentIDs.append(targetArticle.id)
            
            // Build the local notification payload
            let content = UNMutableNotificationContent()
            content.title = "StrikeScore Breaking News"
            content.body = targetArticle.headline
            content.sound = .default
            
            // Set up daily recurring calendar components for the hour slot
            var components = DateComponents()
            components.hour = targetHours[index]
            components.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: slotIdentifiers[index], content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    AppLogger.shared.error("Failed scheduling slot \(slotIdentifiers[index]): \(error.localizedDescription)")
                } else {
                    AppLogger.shared.log("✅ Successfully scheduled headline slot \(targetHours[index]):00 for ID \(targetArticle.id)")
                }
            }
        }
        
        // Persist history logs back to disk safely
        UserDefaults.standard.set(sentIDs, forKey: postedHistoryKey)
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
