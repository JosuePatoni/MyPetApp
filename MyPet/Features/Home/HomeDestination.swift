import Foundation

enum HomeDestination: Hashable, Codable {
    case walks
    case routes
    case reminders

    var title: LocalizedStringResource {
        switch self {
        case .walks: "Mis paseos"
        case .routes: "Recorridos"
        case .reminders: "Mis recordatorios"
        }
    }
}
