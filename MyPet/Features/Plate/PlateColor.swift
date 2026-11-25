import SwiftUI

enum PlateColor: String, CaseIterable, Identifiable {
    case silver
    case gold
    case blue
    case pink

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .silver: "Plateado"
        case .gold: "Dorado"
        case .blue: "Azul"
        case .pink: "Rosa"
        }
    }

    /// Tonos del metal: brillo, color base y sombra (también es el color del grabado).
    /// Azul y rosa imitan aluminio anodizado.
    var shades: (light: Color, base: Color, dark: Color) {
        switch self {
        case .silver: (Color(white: 0.97), Color(white: 0.72), Color(white: 0.45))
        case .gold: (Color(red: 1, green: 0.93, blue: 0.62), Color(red: 0.85, green: 0.66, blue: 0.2), Color(red: 0.55, green: 0.38, blue: 0.05))
        case .blue: (Color(red: 0.65, green: 0.8, blue: 1), Color(red: 0.2, green: 0.42, blue: 0.85), Color(red: 0.06, green: 0.17, blue: 0.45))
        case .pink: (Color(red: 1, green: 0.84, blue: 0.9), Color(red: 0.9, green: 0.45, blue: 0.62), Color(red: 0.58, green: 0.18, blue: 0.36))
        }
    }
}
