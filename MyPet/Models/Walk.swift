import Foundation
import SwiftData

/// Tabla `Paseo`.
@Model
final class Walk {
    var startDate: Date
    var endDate: Date?
    /// Metros.
    var distance: Double = 0
    var startLatitude: Double?
    var startLongitude: Double?
    var endLatitude: Double?
    var endLongitude: Double?
    var experience: Int = 0
    var user: User?
    var pet: Pet?

    @Relationship(deleteRule: .cascade, inverse: \Route.walk)
    var route: Route?

    // ponytail: duración calculada, no guardada, para que nunca se desincronice de las fechas
    var duration: TimeInterval {
        (endDate ?? .now).timeIntervalSince(startDate)
    }

    init(startDate: Date = .now) {
        self.startDate = startDate
    }

    /// 10 XP por cada 100 m completos.
    static func experience(forDistance meters: Double) -> Int {
        Int(max(meters, 0) / 100) * 10
    }

    /// Cierra el paseo y suma la XP a la mascota. Llamarlo dos veces no duplica la XP.
    func complete(distance: Double, at date: Date = .now) {
        guard endDate == nil else { return }
        endDate = date
        self.distance = distance
        experience = Self.experience(forDistance: distance)
        pet?.experience += experience
    }
}
