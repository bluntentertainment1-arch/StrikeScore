import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    /// Requests explicit push notification permission from the user
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                AppLogger.shared.error("Notification authorization configuration error: \(error.localizedDescription)")
                return
            }
            AppLogger.shared.log("Notification permission state: \(granted)")
        }
    }

    /// Schedules daily trending headlines at 9am, 3pm, and 8pm using unrepeated items from editorial news
    /// - Parameter headlines: The raw array of headline strings pulled from your editorial feed
    func scheduleDailyEditorialDigests(headlines: [String]) {
        // Clear all old pending queues to prevent stacking overlapping alerts
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        guard !headlines.isEmpty else {
            AppLogger.shared.log("Skipping daily headlines schedule: Editorial content feed is empty.")
            return
        }

        // Define your target military timeline slots (9:00, 15:00, 20:00)
        let deliveryHours = [9, 15, 20]
        
        // Loop through the hours and assign a unique headline index matching the slot
        for (index, hour) in deliveryHours.enumerated() {
            // Safe array bounds fallback: if there are fewer headlines than slots, cycle back using the modulo operator
            let headlineIndex = index % headlines.count
            let chosenHeadline = headlines[headlineIndex]
            
            // Build the date matching components for the daily trigger
            var dateComponents = DateComponents()
            dateComponents.calendar = Calendar.current
            dateComponents.hour = hour
            dateComponents.minute = 0
            
            // Configure the alert visual structure
            let content = UNMutableNotificationContent()
            content.title = "🔥 Trending Football News"
            content.body = chosenHeadline
            content.sound = .default
            
            // Setting repeats to true means it will fire at this hour every single day automatically
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            // Establish a unique tracking identifier for this specific time block
            let requestIdentifier = "editorial-slot-\(hour)h"
            let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
            
            // Register with the iOS system core
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    AppLogger.shared.error("Failed scheduling news alert for slot \(hour):00: \(error.localizedDescription)")
                } else {
                    AppLogger.shared.log("Successfully armed daily news digest for \(hour):00: \"\(chosenHeadline)\"")
                }
            }
        }
    }
}
