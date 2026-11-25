import Foundation
import SwiftData

/// Tabla `Recompensa`: cupón que un usuario desbloqueó. Copia los textos del catálogo (`RewardCode`)
/// al desbloquearse, para que no cambien si después cambia el catálogo.
@Model
final class Reward {
    /// `RewardCode.rawValue`: evita entregar dos veces el mismo cupón.
    var catalogCode: String
    /// Código de canje único del usuario, p. ej. "HUELLAS20-7K3QX9".
    var code: String
    var title: String
    var details: String
    /// Solo se puede abrir con el plan Pro.
    var isPro: Bool
    var unlockedAt: Date
    var expiresAt: Date
    var user: User?
    var brand: Brand?

    init(catalogCode: String, code: String, title: String, details: String, isPro: Bool, unlockedAt: Date, expiresAt: Date) {
        self.catalogCode = catalogCode
        self.code = code
        self.title = title
        self.details = details
        self.isPro = isPro
        self.unlockedAt = unlockedAt
        self.expiresAt = expiresAt
    }

    var isExpired: Bool { expiresAt < .now }
}
