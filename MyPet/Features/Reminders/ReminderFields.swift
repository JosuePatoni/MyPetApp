import SwiftUI

/// Campos del recordatorio de paseo: cada cuántos días, paseos al día y la hora de cada uno.
struct ReminderFields: View {
    @Binding var draft: ReminderDraft

    var body: some View {
        Toggle("Recordarme pasear", isOn: $draft.isEnabled)

        if draft.isEnabled {
            Stepper(value: $draft.everyDays, in: 1...7) {
                if draft.everyDays == 1 {
                    Text("Todos los días")
                } else {
                    Text("Cada \(draft.everyDays) días")
                }
            }

            if draft.everyDays > 1 {
                DatePicker("A partir del", selection: $draft.startDate, displayedComponents: .date)
            }

            Stepper(value: $draft.walksPerDay, in: 1...4) {
                Text("^[\(draft.walksPerDay) paseo](inflect: true) al día")
            }

            ForEach($draft.times) { $time in
                DatePicker("Paseo \(walkNumber(of: time))", selection: $time.date, displayedComponents: .hourAndMinute)
            }
        }
    }

    private func walkNumber(of time: WalkTime) -> Int {
        (draft.times.firstIndex { $0.id == time.id } ?? 0) + 1
    }
}
