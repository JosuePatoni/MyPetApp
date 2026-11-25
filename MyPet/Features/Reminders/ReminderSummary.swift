import SwiftUI

/// Resumen de una línea o tres del recordatorio: frecuencia, paseos al día y próximo paseo.
struct ReminderSummary: View {
    let reminder: Reminder

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if reminder.isEnabled {
                if reminder.everyDays == 1 {
                    Text("Todos los días")
                } else {
                    Text("Cada \(reminder.everyDays) días")
                }
                Text("^[\(reminder.walksPerDay) paseo](inflect: true) al día")
                if let next = reminder.upcomingDates(limit: 1).first {
                    Text("Próximo: \(next, format: .dateTime.weekday(.wide).hour().minute())")
                }
            } else {
                Text("Recordatorio desactivado")
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}
