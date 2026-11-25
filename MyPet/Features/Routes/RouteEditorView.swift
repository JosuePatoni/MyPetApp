import MapKit
import SwiftData
import SwiftUI

/// "Editar ruta" / "Nuevo recorrido": nombre y puntos tocados en el mapa (primero = inicio, último = final).
struct RouteEditorView: View {
    let user: User

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: RouteEditorViewModel

    init(user: User, route: Route?) {
        self.user = user
        _viewModel = State(initialValue: RouteEditorViewModel(route: route))
    }

    var body: some View {
        VStack(spacing: 0) {
            MapReader { proxy in
                Map(initialPosition: viewModel.isEditing ? .automatic : .userLocation(fallback: .automatic)) {
                    UserAnnotation()
                    if viewModel.points.count > 1 {
                        MapPolyline(coordinates: viewModel.points)
                            .stroke(.blue, lineWidth: 5)
                    }
                    if let first = viewModel.points.first {
                        Marker("Inicio", systemImage: "figure.walk", coordinate: first)
                            .tint(.green)
                    }
                    if viewModel.points.count > 1, let last = viewModel.points.last {
                        Marker("Final", systemImage: "flag.checkered", coordinate: last)
                            .tint(.red)
                    }
                }
                .mapControls { MapUserLocationButton() }
                .onTapGesture { point in
                    if let coordinate = proxy.convert(point, from: .local) {
                        viewModel.add(coordinate)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                TextField("Nombre", text: $viewModel.name)
                    .textFieldStyle(.roundedBorder)

                Text("Toca el mapa para trazar la ruta: el primer punto es el inicio y el último el final.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Button("Deshacer", systemImage: "arrow.uturn.backward", action: viewModel.undo)
                        .disabled(viewModel.points.isEmpty)
                    Button("Borrar", systemImage: "trash", role: .destructive, action: viewModel.clear)
                        .disabled(viewModel.points.isEmpty)
                    Spacer()
                    Text(Format.distance(viewModel.distance))
                        .font(.headline)
                }
                .buttonStyle(.bordered)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.isEditing ? "Editar ruta" : "Nuevo recorrido")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                Task {
                    if await viewModel.save(user: user, in: modelContext) {
                        dismiss()
                    }
                }
            } label: {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Text(viewModel.isEditing ? "Guardar" : "Agregar")
                }
            }
            .disabled(!viewModel.canSave)
        }
    }
}
