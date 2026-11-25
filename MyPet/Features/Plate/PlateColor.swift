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

    var color: Color {
        switch self {
        case .silver: .gray
        case .gold: Color(red: 0.83, green: 0.64, blue: 0.17)
        case .blue: .blue
        case .pink: .pink
        }
    }
}
