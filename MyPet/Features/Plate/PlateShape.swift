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

    /// Zona donde cabe el texto, en fracción del tamaño de la placa: ancho, alto y desplazamiento vertical
    /// (negativo = hacia arriba). El corazón y el escudo son más anchos arriba, por eso el texto sube.
    // ponytail: valores a ojo; si en el simulador el texto se ve chueco o se sale, ajusta aquí
    var textArea: (width: Double, height: Double, offsetY: Double) {
        switch self {
        case .circle: (0.68, 0.62, 0)
        case .heart: (0.58, 0.40, -0.06)
        case .shield: (0.56, 0.50, -0.04)
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
