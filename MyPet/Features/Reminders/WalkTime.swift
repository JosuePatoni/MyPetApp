import Foundation

/// Una hora de paseo editable en el formulario.
struct WalkTime: Identifiable {
    let id = UUID()
    var date: Date

    init(minutes: Int) {
        date = Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: .now) ?? .now
    }

    var minutes: Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}
