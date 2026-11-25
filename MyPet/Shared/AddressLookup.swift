// CLPlacemark aún no es Sendable; @preconcurrency evita errores de Swift 6 al recibirlo.
@preconcurrency import CoreLocation

enum AddressLookup {
    /// "Calle 123, Ciudad"; si no hay red o resultado, las coordenadas.
    static func address(for coordinate: CLLocationCoordinate2D) async -> String {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first
        let parts = [placemark?.name, placemark?.locality].compactMap { $0 }
        if parts.isEmpty {
            return String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude)
        }
        return parts.joined(separator: ", ")
    }
}
