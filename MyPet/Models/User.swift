import Foundation
import SwiftData

/// Tabla `Usuario`. `logro_usuario` y `Paseo_Usuario` se resuelven como relaciones.
@Model
final class User {
    @Attribute(.unique) var username: String
    var email: String
    var passwordHash: Data
    var passwordSalt: Data
    var role: UserRole = UserRole.owner
    var hasCompletedSetup: Bool = false
    /// Pantallas abiertas en el Home; se restauran al volver a entrar.
    var navigationPath: [HomeDestination] = []

    @Relationship(deleteRule: .cascade, inverse: \Pet.owner)
    var pets: [Pet] = []

    @Relationship(deleteRule: .cascade, inverse: \Walk.user)
    var walks: [Walk] = []

    @Relationship(inverse: \Achievement.users)
    var achievements: [Achievement] = []

    @Relationship(deleteRule: .cascade, inverse: \Reminder.user)
    var reminder: Reminder?

    init(username: String, email: String, passwordHash: Data, passwordSalt: Data) {
        self.username = username
        self.email = email
        self.passwordHash = passwordHash
        self.passwordSalt = passwordSalt
    }
}
