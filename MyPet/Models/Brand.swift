import Foundation
import SwiftData

/// Tabla `Marca`: empresa aliada que respalda los cupones. Se precarga desde `BrandCode` al iniciar.
@Model
final class Brand {
    @Attribute(.unique) var code: String
    var name: String
    var symbolName: String
    /// Dónde canjear: tienda en línea y teléfono de atención.
    var website: String
    var phone: String
    var order: Int

    /// Al borrar la marca, los cupones ya entregados se conservan.
    @Relationship(deleteRule: .nullify, inverse: \Reward.brand)
    var rewards: [Reward] = []

    init(code: String, name: String, symbolName: String, website: String, phone: String, order: Int) {
        self.code = code
        self.name = name
        self.symbolName = symbolName
        self.website = website
        self.phone = phone
        self.order = order
    }
}
