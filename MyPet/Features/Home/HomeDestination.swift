import Foundation

/// Pantallas del Home. `Codable` para guardar la ruta del usuario.
enum HomeDestination: Hashable, Codable {
    case walks
    case newWalk
    case routes
    /// `nil` = nuevo recorrido.
    case routeEditor(UUID?)
    case reminders
    case profile
    case rewards
    case pet(UUID)
    case petReminder(UUID)
    case petQR(UUID)
    case petPlate(UUID)
}
