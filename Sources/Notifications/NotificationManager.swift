import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission approved.")
            } else if let error = error {
                print("Authorization failure sequence: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleDailyEditorialNotifications(articles: [EditorialItem]) {
        print("Scheduling reminders for \(articles.count) news updates.")
    }
    
    func scheduleDailyReminders(for matches: [Match]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests() 
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        
        let calendar = Calendar.current
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        
        // ✅ FIXED: Properties changed back to matchDate and matchTime to match the model target
        let activeDailyMatches = matches.filter { match in
            guard let matchDate = formatter.date(from: "\(match.matchDate) \(match.matchTime)") else { return false }
            let matchComponents = calendar.dateComponents([.year, .month, .day], from: matchDate)
            return matchComponents.year == todayComponents.year &&
                   matchComponents.month == todayComponents.month &&
                   matchComponents.day == todayComponents.day
        }
        
        guard !activeDailyMatches.isEmpty else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "⚽ Trending Matches Today"
        content.body = "Don't miss out! Today features \(activeDailyMatches.count) updates waiting on your schedule."
        content.sound = .default
        
        var triggerComponents = DateComponents()
        triggerComponents.hour = 9
        triggerComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_match_summary", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule daily summary: \(error.localizedDescription)")
            }
        }
    }
}
