import SwiftUI

extension Species {
    /// Color de la card de la mascota.
    var tint: Color {
        switch self {
        case .dog: .orange
        case .cat: .purple
        }
    }
}
