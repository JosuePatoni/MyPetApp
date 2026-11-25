import SwiftData
import SwiftUI

struct ReminderSettingsView: View {
    @Bindable var reminder: Reminder

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?

    var body: some View {
        Form {
            ReminderFields(
                isEnabled: $reminder.isEnabled,
                intervalHours: $reminder.intervalHours,
                startTime: $reminder.startTime
            )

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .navigationTitle("Mis recordatorios")
        .toolbar {
            Button("Guardar", action: save)
        }
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        Task { await ReminderScheduler.schedule(reminder) }
        dismiss()
    }
}
