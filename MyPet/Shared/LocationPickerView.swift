// MKMapItem aún no es Sendable; @preconcurrency evita errores de Swift 6 al recibirlo.
@preconcurrency import MapKit
import SwiftUI

/// Hoja para elegir un punto: buscando una dirección o tocando el mapa.
struct LocationPickerView: View {
    let title: LocalizedStringResource
    let onPick: (PickedLocation) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [MKMapItem] = []
    @State private var selection: PickedLocation?
    @State private var position = MapCameraPosition.userLocation(fallback: .automatic)

    var body: some View {
        NavigationStack {
            MapReader { proxy in
                Map(position: $position) {
                    UserAnnotation()
                    if let selection {
                        Marker(selection.name, coordinate: selection.coordinate)
                    }
                }
                .mapControls { MapUserLocationButton() }
                .onTapGesture { point in
                    guard let coordinate = proxy.convert(point, from: .local) else { return }
                    Task {
                        selection = PickedLocation(coordinate: coordinate, name: await AddressLookup.address(for: coordinate))
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Buscar dirección", text: $query)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                    if results.isEmpty {
                        Text("O toca el mapa.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        List(results, id: \.self) { item in
                            Button {
                                select(item)
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
                    }
                }
                .padding()
                .background(.regularMaterial, in: .rect(cornerRadius: 16))
                .padding(.horizontal)
            }
            .task(id: query) { await search() }
            .navigationTitle(Text(title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Usar") {
                        if let selection {
                            onPick(selection)
                        }
                        dismiss()
                    }
                    .disabled(selection == nil)
                }
            }
        }
    }

    private func select(_ item: MKMapItem) {
        let coordinate = item.placemark.coordinate
        selection = PickedLocation(coordinate: coordinate, name: item.name ?? item.placemark.title ?? "")
        position = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500))
        query = ""
        results = []
    }

    /// `.task(id: query)` cancela la búsqueda anterior en cada tecla: eso hace de debounce.
    private func search() async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 3 else {
            results = []
            return
        }
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        request.resultTypes = [.address, .pointOfInterest]
        let items = (try? await MKLocalSearch(request: request).start().mapItems) ?? []
        guard !Task.isCancelled else { return }
        results = items
    }
}
