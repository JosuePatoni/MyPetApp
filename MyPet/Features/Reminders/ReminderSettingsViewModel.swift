import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class ReminderSettingsViewModel {
    var draft: ReminderDraft
    var errorMessage: String?

    init(pet: Pet) {
        draft = pet.reminder.map { ReminderDraft($0) } ?? ReminderDraft()
    }

    func save(pet: Pet, in context: ModelContext) -> Bool {
        let reminder: Reminder
        if let existing = pet.reminder {
            reminder = existing
        } else {
            reminder = Reminder()
            context.insert(reminder)
            pet.reminder = reminder
        }
        draft.apply(to: reminder)

        do {
            try context.save()
        } catch {
            context.rollback()
            errorMessage = error.localizedDescription
            return false
        }
        Task { await ReminderScheduler.schedule(reminder) }
        return true
    }
}
