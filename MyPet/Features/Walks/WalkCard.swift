import MapKit
import SwiftUI

/// Tarjeta del historial. Al tocarla, muestra los detalles y el mapa del paseo.
struct WalkCard: View {
    let walk: Walk
    var headerColor = MyPetPalette.mint

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.snappy) {
                    isExpanded.toggle()
                }
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: "pawprint.fill")
                            .foregroundStyle(MyPetPalette.teal)
                            .accessibilityHidden(true)

                        Text(petNames)
                            .font(.headline)

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .accessibilityHidden(true)
                    }

                    Text(
                        walk.startDate,
                        format: .dateTime.day().month().year().hour().minute()
                    )
                    .font(.subheadline)

                    Text("\(Format.distance(walk.distance)) · \(Format.duration(walk.duration))")
                        .font(.subheadline)
                }
                .foregroundStyle(.black)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(headerColor)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(
                isExpanded ? "Oculta el detalle" : "Muestra el detalle y el mapa"
            )

            if isExpanded {
                details

                map
                    .padding(12)
            }
        }
        .background(Color(uiColor: .systemBackground))
        .clipShape(.rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(MyPetPalette.teal, lineWidth: 1.5)
                .allowsHitTesting(false)
        }
    }

    private var petNames: String {
        walk.pets.isEmpty
            ? String(localized: "Mascota eliminada")
            : walk.pets.map(\.name).formatted(.list(type: .and))
    }

    /// El trazo GPS aparece en naranja y el recorrido personalizado en azul.
    @ViewBuilder
    private var map: some View {
        let track = walk.track

        if track.count > 1 {
            Map(initialPosition: .automatic) {
                if let route = walk.route {
                    MapPolyline(coordinates: route.coordinates)
                        .stroke(.blue.opacity(0.5), lineWidth: 5)
                }

                MapPolyline(coordinates: track)
                    .stroke(.orange, lineWidth: 4)

                if let first = track.first {
                    Marker("Inicio", systemImage: "figure.walk", coordinate: first)
                        .tint(.green)
                }

                if let last = track.last {
                    Marker("Final", systemImage: "flag.checkered", coordinate: last)
                        .tint(.red)
                }
            }
            .mapControlVisibility(.hidden)
            .frame(height: 180)
            .clipShape(.rect(cornerRadius: 12))
            .accessibilityLabel(Text("Mapa del recorrido"))
        } else {
            Label("Sin trazo GPS para mostrar en el mapa", systemImage: "map")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var details: some View {
        Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
            row(
                "Hora inicial",
                walk.startDate.formatted(date: .omitted, time: .standard)
            )
            row(
                "Hora final",
                walk.endDate?.formatted(date: .omitted, time: .standard) ?? "—"
            )
            row("Ubicación inicial", walk.startAddress)
            row("Ubicación final", walk.endAddress)
            row("Duración", Format.duration(walk.duration))
            row(
                "Calorías quemadas",
                Format.calories(of: walk.pets, walking: walk.distance)
            )
            row(
                "Experiencia",
                String(localized: "+\(walk.experience) XP por mascota")
            )
            row(
                "Ruta",
                walk.route?.name ?? String(localized: "No se usó una ruta personalizada")
            )
        }
        .font(.subheadline)
    }

    @ViewBuilder
    private func row(_ label: LocalizedStringResource, _ value: String) -> some View {
        GridRow(alignment: .top) {
            Text(label)
                .fontWeight(.semibold)
                .foregroundStyle(.black)
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(MyPetPalette.yellow)

            Text(value.isEmpty ? "—" : value)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)

        Divider()
            .gridCellUnsizedAxes(.horizontal)
    }
}
