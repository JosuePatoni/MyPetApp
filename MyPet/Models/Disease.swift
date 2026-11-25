import Foundation
import SwiftData

/// Tabla `Enfermedad`.
@Model
final class Disease {
    @Attribute(.unique) var name: String
    var details: String
    var pets: [Pet] = []

    init(name: String, details: String) {
        self.name = name
        self.details = details
    }
}
