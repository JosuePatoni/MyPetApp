import Foundation
import SwiftData

/// Tabla `Recordatorio`: horario de paseo de una mascota (1 mascota → 1 recordatorio).
@Model
final class Reminder {
    /// Prefijo de los identificadores de sus notificaciones.
    var notificationKey: String = UUID().uuidString
    /// 1 = diario, 2 = cada 2 días…
    var everyDays: Int = 1
    /// Día desde el que se cuentan los `everyDays`.
    var startDate: Date = Date.now
    /// Horas de paseo en minutos desde las 00:00, ordenadas.
    var times: [Int] = []
    var isEnabled: Bool = true
    var pet: Pet?

    init() {}

    var walksPerDay: Int { times.count }

    /// Próximas fechas de paseo a partir de `now`.
    func upcomingDates(after now: Date = .now, limit: Int) -> [Date] {
        guard everyDays > 0, !times.isEmpty, limit > 0 else { return [] }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        var day = max(start, calendar.startOfDay(for: now))
        var result: [Date] = []

        while result.count < limit {
            let offset = calendar.dateComponents([.day], from: start, to: day).day ?? 0
            if offset % everyDays == 0 {
                for minutes in times.sorted() {
                    if let date = calendar.date(byAdding: .minute, value: minutes, to: day), date > now {
                        result.append(date)
                    }
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return Array(result.prefix(limit))
    }
}
