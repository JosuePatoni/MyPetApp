// MKRoute aún no es Sendable; @preconcurrency evita errores de Swift 6 al recibirlo.
@preconcurrency import MapKit
import Observation
import SwiftData

/// Formulario "Iniciar un nuevo paseo" + paseo en curso. El `Walk` se crea al finalizar:
/// si la app se cierra a medias no queda un paseo abierto.
@MainActor
@Observable
final class WalkSessionViewModel {
    /// Para seguir un recorrido personalizado hay que estar a esta distancia de su inicio.
    // ponytail: umbral fijo; subirlo si el GPS en interiores no deja empezar
    static let maxDistanceFromRouteStart: CLLocationDistance = 50
    /// ≈ 5 km/h, para estimar la llegada en recorridos personalizados.
    static let walkingSpeed: CLLocationSpeed = 1.4

    // MARK: Formulario

    var selectedPetIDs: Set<UUID> = []
    /// `nil` = la ruta la calcula el sistema entre `startLocation` y `endLocation`.
    var customRoute: Route?
    var startLocation: PickedLocation?
    var endLocation: PickedLocation?
    private(set) var calculatedRoute: MKRoute?
    private(set) var isCalculating = false
    var errorMessage: String?
    private(set) var currentLocation: CLLocation?

    // MARK: Paseo en curso

    var isShowingWalk = false
    private(set) var didFinish = false
    private(set) var isSaving = false
    private(set) var walkStartDate: Date?
    private(set) var walkPets: [Pet] = []
    /// Ruta a seguir (calculada o personalizada) y duración estimada.
    private(set) var plannedPath: [CLLocationCoordinate2D] = []
    private(set) var expectedDuration: TimeInterval?
    private(set) var traveled: [CLLocationCoordinate2D] = []
    private(set) var traveledDistance: CLLocationDistance = 0
    @ObservationIgnored private var lastLocation: CLLocation?
    @ObservationIgnored private var locationTask: Task<Void, Never>?
    @ObservationIgnored private let locationManager = CLLocationManager()

    /// Puntos de la ruta calculada, para dibujarla como camino sugerido.
    var calculatedPath: [CLLocationCoordinate2D] { calculatedRoute?.polyline.coordinates ?? [] }

    var expectedArrival: Date? {
        guard let walkStartDate, let expectedDuration else { return nil }
        return walkStartDate.addingTimeInterval(expectedDuration)
    }

    /// Metros entre tu posición y el inicio del recorrido personalizado; `nil` sin GPS.
    func distanceToStart(of route: Route) -> CLLocationDistance? {
        guard let currentLocation, let start = route.coordinates.first else { return nil }
        return currentLocation.distance(from: CLLocation(latitude: start.latitude, longitude: start.longitude))
    }

    func canStart(with pets: [Pet]) -> Bool {
        guard !pets.isEmpty else { return false }
        if let customRoute {
            return (distanceToStart(of: customRoute) ?? .infinity) <= Self.maxDistanceFromRouteStart
        }
        return endLocation != nil && (startLocation != nil || currentLocation != nil)
    }

    // MARK: GPS

    /// Una sola escucha del GPS mientras viva el view model; se puede llamar varias veces.
    // ponytail: solo en primer plano; para pantalla apagada: UIBackgroundModes location + CLBackgroundActivitySession
    func startLocationUpdates() {
        guard locationTask == nil else { return }
        locationManager.requestWhenInUseAuthorization()
        locationTask = Task { [weak self] in
            do {
                for try await update in CLLocationUpdate.liveUpdates(.fitness) {
                    guard let self else { return }
                    if let location = update.location {
                        self.handle(location)
                    }
                }
            } catch {
                self?.errorMessage = String(localized: "No se pudo obtener tu ubicación.")
            }
        }
    }

    private func handle(_ location: CLLocation) {
        currentLocation = location
        guard walkStartDate != nil, location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 25 else { return }
        if let lastLocation {
            let delta = location.distance(from: lastLocation)
            // ponytail: umbral fijo de 5 m contra el ruido del GPS; ajustarlo si mide de más o de menos
            guard delta >= 5 else { return }
            traveledDistance += delta
        }
        lastLocation = location
        traveled.append(location.coordinate)
    }

    // MARK: Ruta calculada

    /// Ruta a pie más rápida (MapKit, con alternativas) entre inicio (o tu ubicación) y final.
    func calculateRoute() async {
        guard let end = endLocation?.coordinate,
              let start = startLocation?.coordinate ?? currentLocation?.coordinate
        else {
            calculatedRoute = nil
            return
        }
        isCalculating = true
        defer { isCalculating = false }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = .walking
        request.requestsAlternateRoutes = true
        do {
            let response = try await MKDirections(request: request).calculate()
            // La más rápida a pie; si empatan en tiempo, la más corta.
            calculatedRoute = response.routes.min {
                ($0.expectedTravelTime, $0.distance) < ($1.expectedTravelTime, $1.distance)
            }
            errorMessage = nil
        } catch {
            calculatedRoute = nil
            errorMessage = String(localized: "No se encontró una ruta a pie entre esos puntos.")
        }
    }

    // MARK: Paseo

    func startWalk(with pets: [Pet]) {
        if let customRoute {
            plannedPath = customRoute.coordinates
            expectedDuration = customRoute.distance / Self.walkingSpeed
        } else if let calculatedRoute {
            plannedPath = calculatedRoute.polyline.coordinates
            expectedDuration = calculatedRoute.expectedTravelTime
        } else {
            plannedPath = []
            expectedDuration = nil
        }
        walkPets = pets
        walkStartDate = .now
        traveled = []
        traveledDistance = 0
        lastLocation = nil
        errorMessage = nil
        isShowingWalk = true
    }

    func discardWalk() {
        walkStartDate = nil
        walkPets = []
        traveled = []
        traveledDistance = 0
        isShowingWalk = false
    }

    /// Guarda el `Walk` con su trazo, direcciones y recorrido, y da a cada mascota 10 XP por cada 100 m.
    func finishWalk(user: User, in context: ModelContext) async {
        guard let walkStartDate, !isSaving else { return }
        let endDate = Date.now
        isSaving = true
        defer { isSaving = false }

        let first = traveled.first ?? plannedPath.first ?? currentLocation?.coordinate
        let last = traveled.last ?? currentLocation?.coordinate ?? first
        var startAddress = ""
        var endAddress = ""
        if let first { startAddress = await AddressLookup.address(for: first) }
        if let last { endAddress = await AddressLookup.address(for: last) }

        let walk = Walk(startDate: walkStartDate)
        context.insert(walk)
        walk.user = user
        walk.pets = walkPets
        walk.route = customRoute
        walk.track = traveled
        walk.plannedPath = plannedPath
        walk.startLatitude = first?.latitude
        walk.startLongitude = first?.longitude
        walk.endLatitude = last?.latitude
        walk.endLongitude = last?.longitude
        walk.startAddress = startAddress
        walk.endAddress = endAddress
        walk.complete(distance: traveledDistance, at: endDate)

        do {
            try context.save()
            discardWalk()
            didFinish = true
        } catch {
            context.rollback()
            errorMessage = error.localizedDescription
        }
    }
}

private extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var result = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&result, range: NSRange(location: 0, length: pointCount))
        return result
    }
}
