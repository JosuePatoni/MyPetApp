import Foundation

/// Pantallas del Home. `Codable` para guardar la ruta del usuario.
enum HomeDestination: Hashable, Codable {
    case walks
    case routes
    case reminders
    case pet(UUID)
    case petReminder(UUID)

    var title: LocalizedStringResource {
        switch self {
        case .walks: "Mis paseos"
        case .routes: "Recorridos"
        case .reminders: "Mis recordatorios"
        case .pet: "Mascota"
        case .petReminder: "Recordatorio"
        }
    }
}
