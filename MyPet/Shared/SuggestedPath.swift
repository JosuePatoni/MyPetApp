import MapKit
import SwiftUI

/// Camino sugerido sobre un `Map`: línea azul con borde blanco, como en Apple Maps.
/// Lo caminado se dibuja aparte en naranja, encima.
struct SuggestedPath: MapContent {
    let coordinates: [CLLocationCoordinate2D]

    var body: some MapContent {
        MapPolyline(coordinates: coordinates)
            .stroke(.white, style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
        MapPolyline(coordinates: coordinates)
            .stroke(.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
    }
}
