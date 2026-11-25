import CoreLocation
import Foundation
import SwiftData

/// Tabla `Paseo`: un paseo terminado de una o varias mascotas, con su trazo GPS real.
@Model
final class Walk {
    var startDate: Date
    var endDate: Date?
    /// Metros recorridos según el GPS.
    var distance: Double = 0
    var startLatitude: Double?
    var startLongitude: Double?
    var endLatitude: Double?
    var endLongitude: Double?
    var startAddress: String = ""
    var endAddress: String = ""
    /// XP que ganó cada mascota del paseo.
    var experience: Int = 0
    /// Trazo GPS real (dos arreglos: SwiftData los guarda sin codificar).
    var trackLatitudes: [Double] = []
    var trackLongitudes: [Double] = []
    /// Camino sugerido al iniciar (ruta calculada o recorrido personalizado), tal como era ese día.
    var plannedLatitudes: [Double] = []
    var plannedLongitudes: [Double] = []
    var user: User?
    /// Inversa declarada en `Pet.walks` (muchos a muchos).
    var pets: [Pet] = []
    /// Recorrido personalizado que se siguió; `nil` si la ruta la calculó el sistema. Inversa en `Route.walks`.
    var route: Route?

    // ponytail: duración calculada, no guardada, para que nunca se desincronice de las fechas
    var duration: TimeInterval {
        (endDate ?? .now).timeIntervalSince(startDate)
    }

    var track: [CLLocationCoordinate2D] {
        get { zip(trackLatitudes, trackLongitudes).map { CLLocationCoordinate2D(latitude: $0, longitude: $1) } }
        set {
            trackLatitudes = newValue.map(\.latitude)
            trackLongitudes = newValue.map(\.longitude)
        }
    }

    var plannedPath: [CLLocationCoordinate2D] {
        get { zip(plannedLatitudes, plannedLongitudes).map { CLLocationCoordinate2D(latitude: $0, longitude: $1) } }
        set {
            plannedLatitudes = newValue.map(\.latitude)
            plannedLongitudes = newValue.map(\.longitude)
        }
    }

    init(startDate: Date = .now) {
        self.startDate = startDate
    }

    /// 10 XP por cada 100 m completos.
    static func experience(forDistance meters: Double) -> Int {
        Int(max(meters, 0) / 100) * 10
    }

    /// kcal estimadas de un animal de `weight` kg que camina `meters`.
    /// Costo neto de transporte de Taylor et al. (1982): 10.7 · M^-0.316 J/(kg·m) ⇒ 10.7 · M^0.684 J/m.
    /// Ej.: perro de 10 kg, 1 km ≈ 12 kcal; gato de 4 kg, 1 km ≈ 6.6 kcal.
    // ponytail: usa el peso actual de la mascota, no el del día del paseo; guardarlo por paseo si importa
    static func calories(walking meters: Double, weight: Double?) -> Double? {
        guard let weight, weight > 0 else { return nil }
        return 10.7 * pow(weight, 0.684) * max(meters, 0) / 4184
    }

    /// Cierra el paseo y suma la XP a cada mascota. Llamarlo dos veces no duplica la XP.
    func complete(distance: Double, at date: Date = .now) {
        guard endDate == nil else { return }
        endDate = date
        self.distance = distance
        experience = Self.experience(forDistance: distance)
        for pet in pets {
            pet.experience += experience
        }
    }
}
