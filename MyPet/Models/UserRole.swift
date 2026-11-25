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

    var summary: LocalizedStringResource {
        switch self {
        case .owner: "Registra a tus mascotas, sus paseos, su QR y su placa."
        case .walker: "Pasea mascotas y lleva el registro de cada recorrido."
        }
    }

    var symbolName: String {
        switch self {
        case .owner: "house.circle.fill"
        case .walker: "figure.walk.circle.fill"
        }
    }

    /// Título de la sección de mascotas en el Home.
    var petsTitle: LocalizedStringResource {
        switch self {
        case .owner: "Mis mascotas"
        case .walker: "Mascotas que paseo"
        }
    }
}
