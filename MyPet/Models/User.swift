import CoreLocation
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
    /// Contacto del dueño para el QR y la placa; se pide la primera vez que se genera un QR.
    var address: String = ""
    var phone: String = ""
    @Attribute(.externalStorage) var photoData: Data?
    /// Plan Pro (compra simulada): abre los cupones Pro y permite filtrar marcas.
    var isPro: Bool = false
    /// Marcas que el usuario ocultó en Recompensas (solo Pro puede cambiarlas).
    var hiddenBrandCodes: [String] = []
    /// Ruta del Home en JSON: SwiftData no guarda de forma fiable enums con valores asociados.
    var navigationPathData: Data?

    @Relationship(deleteRule: .cascade, inverse: \Pet.owner)
    var pets: [Pet] = []

    @Relationship(deleteRule: .cascade, inverse: \Walk.user)
    var walks: [Walk] = []

    @Relationship(deleteRule: .cascade, inverse: \Route.user)
    var routes: [Route] = []

    @Relationship(deleteRule: .cascade, inverse: \Reward.user)
    var rewards: [Reward] = []

    @Relationship(inverse: \Achievement.users)
    var achievements: [Achievement] = []

    init(username: String, email: String, passwordHash: Data, passwordSalt: Data) {
        self.username = username
        self.email = email
        self.passwordHash = passwordHash
        self.passwordSalt = passwordSalt
    }

    // ponytail: suma calculada en cada lectura; guardar un acumulado si hay miles de paseos
    /// Metros caminados en todos sus paseos (el perfil los muestra en km).
    var walkedDistance: CLLocationDistance { walks.reduce(0) { $0 + $1.distance } }

    /// Pantallas abiertas en el Home; se restauran al volver a entrar.
    var navigationPath: [HomeDestination] {
        get { navigationPathData.flatMap { try? JSONDecoder().decode([HomeDestination].self, from: $0) } ?? [] }
        set { navigationPathData = try? JSONEncoder().encode(newValue) }
    }
}
