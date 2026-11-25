import SwiftData
import SwiftUI

/// "Mis recorridos": rutas personalizadas guardadas, con editar y eliminar.
struct RoutesListView: View {
    let user: User

    @Environment(\.modelContext) private var modelContext
    @State private var routeToDelete: Route?

    private var routes: [Route] {
        user.routes.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        List {
            Section {
                NavigationLink(value: HomeDestination.routeEditor(nil)) {
                    Label("Añadir recorrido personalizado", systemImage: "plus")
                }
            }

            Section("Recorridos guardados") {
                if routes.isEmpty {
                    Text("Aún no tienes recorridos.")
                        .foregroundStyle(.secondary)
                }
                ForEach(routes) { route in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ruta: \(route.name)")
                                .font(.headline)
                            Text("Inicio: \(route.startAddress)")
                            Text("Final: \(route.endAddress)")
                            Text("Distancia: \(Format.distance(route.distance))")
                        }
                        .font(.subheadline)
                        .accessibilityElement(children: .combine)

                        Spacer()

                        Menu("Opciones", systemImage: "ellipsis") {
                            Button("Editar", systemImage: "pencil") { edit(route) }
                            Button("Eliminar", systemImage: "trash", role: .destructive) { routeToDelete = route }
                        }
                        .labelStyle(.iconOnly)
                    }
                    .swipeActions {
                        Button("Eliminar", systemImage: "trash", role: .destructive) { routeToDelete = route }
                        Button("Editar", systemImage: "pencil") { edit(route) }
                    }
                }
            }
        }
        .navigationTitle("Mis recorridos")
        .confirmationDialog(
            "¿Eliminar este recorrido?",
            isPresented: Binding { routeToDelete != nil } set: { if !$0 { routeToDelete = nil } },
            titleVisibility: .visible,
            presenting: routeToDelete
        ) { route in
            Button("Eliminar", role: .destructive) { delete(route) }
        } message: { _ in
            Text("Los paseos que lo usaron se conservan, sin recorrido.")
        }
    }

    private func edit(_ route: Route) {
        user.navigationPath.append(.routeEditor(route.uuid))
    }

    private func delete(_ route: Route) {
        user.routes.removeAll { $0.uuid == route.uuid }
        modelContext.delete(route)
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
        }
    }
}
