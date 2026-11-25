import CoreLocation
import Foundation
import SwiftData

/// Tabla `Ruta`: recorrido personalizado que el usuario traza tocando el mapa y reutiliza en sus paseos.
@Model
final class Route {
    /// Identificador estable para la ruta de navegación guardada.
    var uuid: UUID = UUID()
    var name: String
    var latitudes: [Double] = []
    var longitudes: [Double] = []
    var startAddress: String = ""
    var endAddress: String = ""
    var user: User?

    /// Al borrar el recorrido, los paseos se conservan y quedan sin recorrido.
    @Relationship(deleteRule: .nullify, inverse: \Walk.route)
    var walks: [Walk] = []

    init(name: String) {
        self.name = name
    }

    var coordinates: [CLLocationCoordinate2D] {
        get { zip(latitudes, longitudes).map { CLLocationCoordinate2D(latitude: $0, longitude: $1) } }
        set {
            latitudes = newValue.map(\.latitude)
            longitudes = newValue.map(\.longitude)
        }
    }

    /// Metros, sumando los tramos rectos entre puntos.
    var distance: CLLocationDistance { Self.length(of: coordinates) }

    static func length(of points: [CLLocationCoordinate2D]) -> CLLocationDistance {
        zip(points, points.dropFirst()).reduce(0) { total, pair in
            total + CLLocation(latitude: pair.0.latitude, longitude: pair.0.longitude)
                .distance(from: CLLocation(latitude: pair.1.latitude, longitude: pair.1.longitude))
        }
    }
}
