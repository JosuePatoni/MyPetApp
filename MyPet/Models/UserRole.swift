import Foundation

/// tipoUsuario.
enum UserRole: String, Codable, CaseIterable, Identifiable {
    case owner
    case walker

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .owner: "Dueño"
        case .walker: "Paseador"
        }
    }
}
