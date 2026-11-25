// MKMapItem aún no es Sendable; @preconcurrency evita errores de Swift 6 al recibirlo.
@preconcurrency import MapKit
import SwiftUI

/// Elegir inicio y destino tipo Uber/DiDi: al escoger el inicio se acepta solo y pasa al destino;
/// al escoger el destino se dibuja la ruta a pie más rápida.
struct RoutePlannerView: View {
    let viewModel: WalkSessionViewModel

    private enum Field: Hashable {
        case start
        case end
    }

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focus: Field?
    @State private var startText: String
    @State private var endText: String
    @State private var results: [MKMapItem] = []
    @State private var position = MapCameraPosition.userLocation(fallback: .automatic)

    init(viewModel: WalkSessionViewModel) {
        self.viewModel = viewModel
        _startText = State(initialValue: viewModel.startLocation?.name ?? "")
        _endText = State(initialValue: viewModel.endLocation?.name ?? "")
    }

    var body: some View {
        NavigationStack {
            MapReader { proxy in
                Map(position: $position) {
                    UserAnnotation()
                    if viewModel.calculatedPath.count > 1 {
                        SuggestedPath(coordinates: viewModel.calculatedPath)
                    }
                    if let start = viewModel.startLocation {
                        Marker("Inicio", systemImage: "figure.walk", coordinate: start.coordinate)
                            .tint(.green)
                    }
                    if let end = viewModel.endLocation {
                        Marker("Destino", systemImage: "flag.checkered", coordinate: end.coordinate)
                            .tint(.red)
                    }
                }
                .mapControls { MapUserLocationButton() }
                // Tocar el mapa llena el campo activo; si no hay ninguno activo, el destino.
                .onTapGesture { point in
                    guard let coordinate = proxy.convert(point, from: .local) else { return }
                    let field = focus ?? .end
                    Task {
                        let location = PickedLocation(coordinate: coordinate, name: await AddressLookup.address(for: coordinate))
                        await pick(location, for: field)
                    }
                }
            }
            .safeAreaInset(edge: .top) { searchPanel }
            .safeAreaInset(edge: .bottom) { routePanel }
            .task(id: startText) { await search(startText, for: .start) }
            .task(id: endText) { await search(endText, for: .end) }
            .onAppear {
                focus = viewModel.startLocation == nil && viewModel.endLocation == nil ? .start : .end
            }
            .navigationTitle("Elegir ruta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
        }
    }

    private var searchPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)
                TextField("Inicio: mi ubicación", text: $startText)
                    .focused($focus, equals: .start)
                    .submitLabel(.next)
            }
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(.red)
                    .accessibilityHidden(true)
                TextField("¿A dónde van?", text: $endText)
                    .focused($focus, equals: .end)
                    .submitLabel(.search)
            }

            if !results.isEmpty, let field = focus {
                List(results, id: \.self) { item in
                    Button {
                        let location = PickedLocation(
                            coordinate: item.placemark.coordinate,
                            name: item.name ?? item.placemark.title ?? ""
                        )
                        Task { await pick(location, for: field) }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(item.name ?? "")
                            Text(item.placemark.title ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
                .frame(maxHeight: 240)
            } else {
                Text("Busca una dirección o toca el mapa.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .textFieldStyle(.roundedBorder)
        .autocorrectionDisabled()
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
        .padding(.horizontal)
    }

    @ViewBuilder
    private var routePanel: some View {
        if viewModel.isCalculating {
            ProgressView("Calculando ruta…")
                .padding()
                .background(.regularMaterial, in: .rect(cornerRadius: 16))
                .padding()
        } else if let route = viewModel.calculatedRoute {
            HStack {
                PetStat(value: Text(Format.distance(route.distance)), label: "Distancia")
                PetStat(value: Text(Format.duration(route.expectedTravelTime)), label: "A pie")
            }
            .padding()
            .background(.regularMaterial, in: .rect(cornerRadius: 16))
            .padding()
        } else if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .foregroundStyle(.red)
                .padding()
                .background(.regularMaterial, in: .rect(cornerRadius: 16))
                .padding()
        }
    }

    /// Busca solo si el texto lo escribió el usuario: al elegir un lugar el campo conserva su nombre sin volver a buscar.
    private func search(_ text: String, for field: Field) async {
        let selectedName = field == .start ? viewModel.startLocation?.name : viewModel.endLocation?.name
        if field == .start, text.isEmpty, viewModel.startLocation != nil {
            viewModel.startLocation = nil // vacío = salir desde mi ubicación
            await viewModel.calculateRoute()
        }
        guard focus == field, text != selectedName else { return }
        let items = await PlaceSearch.items(matching: text, near: viewModel.currentLocation?.coordinate)
        guard !Task.isCancelled, focus == field else { return }
        results = items
    }

    /// Fija el punto, conserva su nombre en el campo y avanza: inicio → destino → dibuja la ruta.
    private func pick(_ location: PickedLocation, for field: Field) async {
        results = []
        switch field {
        case .start:
            viewModel.startLocation = location
            startText = location.name
            focus = .end
        case .end:
            viewModel.endLocation = location
            endText = location.name
            focus = nil
        }
        await viewModel.calculateRoute()
        if let rect = viewModel.calculatedRoute?.polyline.boundingMapRect {
            position = .rect(rect.insetBy(dx: -rect.width * 0.3, dy: -rect.height * 0.3))
        } else {
            position = .region(MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 800, longitudinalMeters: 800))
        }
    }
}
