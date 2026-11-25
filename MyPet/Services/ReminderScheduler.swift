import Foundation
import SwiftData
import UserNotifications

/// Programa las notificaciones locales de paseo de cada mascota.
enum ReminderScheduler {
    private static let maxDatedRequests = 10

    /// Se llama al abrir la app para renovar los recordatorios "cada N días".
    /// ponytail: reprograma los de todos los usuarios del dispositivo; filtrar por sesión si importa
    @MainActor
    static func rescheduleAll(in context: ModelContext) async {
        for reminder in (try? context.fetch(FetchDescriptor<Reminder>())) ?? [] {
            await schedule(reminder)
        }
    }

    @MainActor
    static func schedule(_ reminder: Reminder) async {
        var triggers: [(components: DateComponents, repeats: Bool)] = []
        if reminder.isEnabled {
            if reminder.everyDays == 1 {
                triggers = reminder.times.map { (DateComponents(hour: $0 / 60, minute: $0 % 60), true) }
            } else {
                // ponytail: iOS no repite "cada N días" a una hora fija; se programan las próximas 10 fechas
                // y se renuevan al abrir la app. Si no se abre en ese lapso, dejan de llegar.
                let calendar = Calendar.current
                triggers = reminder.upcomingDates(limit: maxDatedRequests).map {
                    (calendar.dateComponents([.year, .month, .day, .hour, .minute], from: $0), false)
                }
            }
        }
        let petName = reminder.pet?.name ?? String(localized: "Tu mascota")
        let body = String(localized: "\(petName) te está esperando.")
        await replacePending(prefix: reminder.notificationKey, triggers: triggers, body: body)
    }

    private static func replacePending(
        prefix: String,
        triggers: [(components: DateComponents, repeats: Bool)],
        body: String
    ) async {
        let center = UNUserNotificationCenter.current()
        let old = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: old)

        guard !triggers.isEmpty,
              (try? await center.requestAuthorization(options: [.alert, .sound])) == true
        else { return }

        for (index, item) in triggers.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = String(localized: "¡Hora del paseo! 🐾")
            content.body = body
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: item.components, repeats: item.repeats)
            try? await center.add(UNNotificationRequest(identifier: "\(prefix)-\(index)", content: content, trigger: trigger))
        }
    }
}
