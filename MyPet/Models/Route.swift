import Foundation
import SwiftData

/// Tabla `Ruta`.
@Model
final class Route {
    /// Polyline codificada (formato Google Encoded Polyline).
    var encodedPolyline: String
    var pointCount: Int
    var walk: Walk?

    init(encodedPolyline: String, pointCount: Int) {
        self.encodedPolyline = encodedPolyline
        self.pointCount = pointCount
    }
}
