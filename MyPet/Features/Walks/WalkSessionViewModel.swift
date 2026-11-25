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
    /// Paradas pet friendly registradas en este paseo (nombres de los lugares).
    private(set) var petFriendlyStops: [String] = []
    private(set) var isFindingStop = false
    /// Resultado del último intento de registrar parada, para mostrarlo bajo el botón.
    private(set) var stopMessage: String?
    /// Una parada cuenta si el lugar está a esta distancia o menos.
    static let petFriendlyRadius: CLLocationDistance = 100
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
                    guard !Task.isCancelled, let self else { return }
                    if let location = update.location {
                        self.handle(location)
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                self?.errorMessage = String(localized: "No se pudo obtener tu ubicación.")
            }
        }
    }

    func stopLocationUpdates() {
        locationTask?.cancel()
        locationTask = nil
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
        petFriendlyStops = []
        stopMessage = nil
        lastLocation = nil
        errorMessage = nil
        isShowingWalk = true
    }

    func discardWalk() {
        stopLocationUpdates()
        walkStartDate = nil
        walkPets = []
        traveled = []
        traveledDistance = 0
        petFriendlyStops = []
        stopMessage = nil
        isShowingWalk = false
    }

    /// Busca con MapKit el lugar pet friendly más cercano (≤ 100 m) y lo registra como parada del paseo.
    func registerPetFriendlyStop() async {
        guard let location = currentLocation else {
            stopMessage = String(localized: "Aún no tenemos tu ubicación. Intenta de nuevo en unos segundos.")
            return
        }
        isFindingStop = true
        defer { isFindingStop = false }

        var categories: [MKPointOfInterestCategory] = [.park, .nationalPark]
        if #available(iOS 18.0, *) {
            categories.append(.animalService) // veterinarias, estéticas y tiendas de mascotas
        }
        let poiRequest = MKLocalPointsOfInterestRequest(center: location.coordinate, radius: Self.petFriendlyRadius)
        poiRequest.pointOfInterestFilter = MKPointOfInterestFilter(including: categories)
        var items = (try? await MKLocalSearch(request: poiRequest).start().mapItems) ?? []

        // iOS 17 no tiene categoría de servicios para animales: se buscan por texto.
        let textRequest = MKLocalSearch.Request()
        textRequest.naturalLanguageQuery = String(localized: "veterinaria tienda de mascotas")
        textRequest.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: Self.petFriendlyRadius * 2,
            longitudinalMeters: Self.petFriendlyRadius * 2
        )
        items += (try? await MKLocalSearch(request: textRequest).start().mapItems) ?? []

        let nearest = items
            .compactMap { item -> (name: String, distance: CLLocationDistance)? in
                guard let name = item.name, let place = item.placemark.location else { return nil }
                return (name: name, distance: place.distance(from: location))
            }
            .filter { $0.distance <= Self.petFriendlyRadius }
            .min { $0.distance < $1.distance }

        guard let nearest else {
            stopMessage = String(localized: "No hay un parque, veterinaria o tienda de mascotas a menos de 100 m.")
            return
        }
        guard !petFriendlyStops.contains(nearest.name) else {
            stopMessage = String(localized: "Ya registraste \(nearest.name) en este paseo.")
            return
        }
        petFriendlyStops.append(nearest.name)
        stopMessage = String(localized: "Parada registrada: \(nearest.name)")
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
        walk.petFriendlyStops = petFriendlyStops
        walk.startLatitude = first?.latitude
        walk.startLongitude = first?.longitude
        walk.endLatitude = last?.latitude
        walk.endLongitude = last?.longitude
        walk.startAddress = startAddress
        walk.endAddress = endAddress
        walk.complete(distance: traveledDistance, at: endDate)
        // La distancia, las paradas y el paseo nuevo pueden desbloquear logros (XP para las mascotas del paseo) y cupones.
        AchievementService(context: context).evaluate(for: user, rewarding: walkPets)
        RewardService(context: context).evaluate(for: user)

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
