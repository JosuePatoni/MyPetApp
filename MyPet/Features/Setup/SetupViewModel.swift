import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class SetupViewModel {
    var role = UserRole.owner
    var isReminderEnabled = true
    var intervalHours = 4
    var startTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now) ?? .now
    var errorMessage: String?

    func finish(user: User, in context: ModelContext) async {
        let reminder = Reminder(intervalHours: intervalHours, startTime: startTime, isEnabled: isReminderEnabled)
        context.insert(reminder)
        user.reminder = reminder
        user.role = role
        user.hasCompletedSetup = true

        do {
            try context.save()
        } catch {
            context.rollback()
            errorMessage = error.localizedDescription
            return
        }
        await ReminderScheduler.schedule(reminder)
    }
}
