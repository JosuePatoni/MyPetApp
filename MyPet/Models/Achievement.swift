import Foundation
import SwiftData

/// Tabla `Logro`. Se precarga desde `AchievementCode` al iniciar la app.
@Model
final class Achievement {
    @Attribute(.unique) var code: String
    var name: String
    var details: String
    /// XP que gana la mascota que desbloquea el logro.
    var experience: Int
    var order: Int
    var users: [User] = []

    init(code: String, name: String, details: String, experience: Int, order: Int) {
        self.code = code
        self.name = name
        self.details = details
        self.experience = experience
        self.order = order
    }
}
