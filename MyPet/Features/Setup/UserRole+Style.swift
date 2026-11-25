import SwiftUI

extension UserRole {
    /// Color del rol, de la paleta del proyecto (`MyPetPalette`).
    var tint: Color {
        switch self {
        case .owner: MyPetPalette.yellow
        case .walker: MyPetPalette.turquoise
        }
    }
}
