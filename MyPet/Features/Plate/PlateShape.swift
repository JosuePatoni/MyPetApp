import Foundation

/// Formas de la placa. ponytail: SF Symbols no tiene hueso; dibujar un `Shape` propio si se pide.
enum PlateShape: String, CaseIterable, Identifiable {
    case circle
    case heart
    case shield

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .circle: "Círculo"
        case .heart: "Corazón"
        case .shield: "Escudo"
        }
    }

    var symbolName: String {
        switch self {
        case .circle: "circle.fill"
        case .heart: "heart.fill"
        case .shield: "shield.fill"
        }
    }
}
