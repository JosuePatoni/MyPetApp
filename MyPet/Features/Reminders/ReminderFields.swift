import SwiftUI

/// Campos del recordatorio, compartidos por la configuración inicial y "Mis recordatorios".
struct ReminderFields: View {
    @Binding var isEnabled: Bool
    @Binding var intervalHours: Int
    @Binding var startTime: Date

    var body: some View {
        Toggle("Recordarme pasear", isOn: $isEnabled)

        if isEnabled {
            Picker("Pasear cada", selection: $intervalHours) {
                ForEach(Reminder.intervalOptions, id: \.self) { hours in
                    Text("\(hours) h").tag(hours)
                }
            }
            DatePicker("Primer paseo del día", selection: $startTime, displayedComponents: .hourAndMinute)
        }
    }
}
