import CoreLocation
import Observation
import SwiftData

/// Crear o editar un recorrido personalizado: nombre + puntos tocados en el mapa.
@MainActor
@Observable
final class RouteEditorViewModel {
    let route: Route?
    var name: String
    private(set) var points: [CLLocationCoordinate2D]
    private(set) var isSaving = false
    var errorMessage: String?

    init(route: Route?) {
        self.route = route
        name = route?.name ?? ""
        points = route?.coordinates ?? []
    }

    var isEditing: Bool { route != nil }
    var distance: CLLocationDistance { Route.length(of: points) }

    var canSave: Bool {
        !isSaving && points.count >= 2 && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func add(_ point: CLLocationCoordinate2D) { points.append(point) }
    func undo() { _ = points.popLast() }
    func clear() { points.removeAll() }

    /// Busca las direcciones del primer y último punto y guarda.
    func save(user: User, in context: ModelContext) async -> Bool {
        guard canSave, let first = points.first, let last = points.last else { return false }
        isSaving = true
        defer { isSaving = false }
        let startAddress = await AddressLookup.address(for: first)
        let endAddress = await AddressLookup.address(for: last)

        let target: Route
        if let route {
            target = route
        } else {
            target = Route(name: "")
            context.insert(target)
            target.user = user
        }
        target.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        target.coordinates = points
        target.startAddress = startAddress
        target.endAddress = endAddress

        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            errorMessage = error.localizedDescription
            return false
        }
    }
}
