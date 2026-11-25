import CoreLocation

/// Punto elegido en el mapa con su dirección legible.
struct PickedLocation {
    var coordinate: CLLocationCoordinate2D
    var name: String
}
