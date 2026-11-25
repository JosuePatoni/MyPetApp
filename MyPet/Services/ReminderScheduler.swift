import Foundation
import UserNotifications

/// Programa notificaciones locales diarias según el `Reminder`.
enum ReminderScheduler {
    private static let maxRequests = 24

    @MainActor
    static func schedule(_ reminder: Reminder) async {
        await replacePending(with: reminder.isEnabled ? reminder.dailyTimes : [])
    }

    private static func replacePending(with times: [DateComponents]) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: (0..<maxRequests).map(identifier))

        guard !times.isEmpty,
              (try? await center.requestAuthorization(options: [.alert, .sound])) == true
        else { return }

        for (index, time) in times.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = String(localized: "¡Hora del paseo! 🐾")
            content.body = String(localized: "Tu mascota te está esperando.")
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
            try? await center.add(UNNotificationRequest(identifier: identifier(index), content: content, trigger: trigger))
        }
    }

    private static func identifier(_ index: Int) -> String {
        "walk-reminder-\(index)"
    }
}
