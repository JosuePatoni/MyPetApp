// MKMapItem aún no es Sendable; @preconcurrency evita errores de Swift 6 al recibirlo.
@preconcurrency import MapKit

enum PlaceSearch {
    /// Direcciones y lugares que coinciden con `text`, priorizando los cercanos a `center`.
    /// Espera 300 ms antes de buscar: llamado desde `.task(id: texto)`, cada tecla cancela la búsqueda anterior.
    static func items(matching text: String, near center: CLLocationCoordinate2D?) async -> [MKMapItem] {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 3 else { return [] }
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return [] }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        request.resultTypes = [.address, .pointOfInterest]
        if let center {
            request.region = MKCoordinateRegion(center: center, latitudinalMeters: 20_000, longitudinalMeters: 20_000)
        }
        return (try? await MKLocalSearch(request: request).start().mapItems) ?? []
    }
}
