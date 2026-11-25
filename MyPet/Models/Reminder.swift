import Foundation
import SwiftData

/// Tabla `Recordatorio`: cada cuánto se pasea al perro. Se crea en la configuración inicial.
/// ponytail: un recordatorio por usuario; pasar a uno por mascota si se necesita.
@Model
final class Reminder {
    /// Divisores de 24 para que el horario se repita igual cada día.
    static let intervalOptions = [2, 3, 4, 6, 8, 12, 24]

    var intervalHours: Int
    /// Solo se usan hora y minuto: primer paseo del día.
    var startTime: Date
    var isEnabled: Bool
    var user: User?

    init(intervalHours: Int, startTime: Date, isEnabled: Bool) {
        self.intervalHours = intervalHours
        self.startTime = startTime
        self.isEnabled = isEnabled
    }

    /// Horas del día en las que toca paseo, p. ej. inicio 8:00 cada 6 h → 8:00, 14:00, 20:00, 2:00.
    var dailyTimes: [DateComponents] {
        let start = Calendar.current.dateComponents([.hour, .minute], from: startTime)
        return stride(from: 0, to: 24, by: max(intervalHours, 1)).map { offset in
            DateComponents(hour: ((start.hour ?? 0) + offset) % 24, minute: start.minute)
        }
    }
}
