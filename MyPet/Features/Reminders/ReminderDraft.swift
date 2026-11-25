import Foundation

/// Copia editable de un `Reminder` para los formularios; se aplica al guardar.
struct ReminderDraft {
    var isEnabled = true
    var everyDays = 1
    var startDate = Date.now
    var times = [WalkTime(minutes: 8 * 60)]

    /// Paseos al día = cantidad de horas. Al subirlo agrega una hora 4 h después de la última.
    var walksPerDay: Int {
        get { times.count }
        set {
            while times.count < newValue {
                times.append(WalkTime(minutes: min((times.last?.minutes ?? 8 * 60) + 4 * 60, 23 * 60 + 59)))
            }
            if times.count > newValue {
                times.removeLast(times.count - newValue)
            }
        }
    }

    init() {}

    init(_ reminder: Reminder) {
        isEnabled = reminder.isEnabled
        everyDays = reminder.everyDays
        startDate = reminder.startDate
        if !reminder.times.isEmpty {
            times = reminder.times.map { WalkTime(minutes: $0) }
        }
    }

    func apply(to reminder: Reminder) {
        reminder.isEnabled = isEnabled
        reminder.everyDays = everyDays
        reminder.startDate = Calendar.current.startOfDay(for: startDate)
        reminder.times = Set(times.map(\.minutes)).sorted()
    }
}
