import MapKit
import SwiftUI

/// Card del historial: resumen compacto; al tocarla se despliega el detalle de la tabla `Paseo` y el mapa del recorrido.
struct WalkCard: View {
    let walk: Walk

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.snappy) { isExpanded.toggle() }
            } label: {
                summary
            }
            .buttonStyle(.plain)
            .accessibilityHint(isExpanded ? "Oculta el detalle" : "Muestra el detalle y el mapa")

            if isExpanded {
                Divider()
                map
                details
            }
        }
        .padding()
        .background(.fill.tertiary, in: .rect(cornerRadius: 16))
    }

    /// Camino sugerido guardado; los paseos anteriores a este cambio solo tienen su recorrido personalizado.
    private var suggestedPath: [CLLocationCoordinate2D] {
        let planned = walk.plannedPath
        return planned.isEmpty ? (walk.route?.coordinates ?? []) : planned
    }

    private var petNames: String {
        walk.pets.isEmpty ? String(localized: "Mascota eliminada") : walk.pets.map(\.name).formatted(.list(type: .and))
    }

    /// Una fila: captura del recorrido, mascotas y fecha; a la derecha distancia y duración.
    private var summary: some View {
        HStack(spacing: 12) {
            RouteThumbnail(planned: suggestedPath, track: walk.track)

            VStack(alignment: .leading, spacing: 2) {
                Text(petNames)
                    .font(.headline)
                    .lineLimit(1)
                Text(walk.startDate, format: .dateTime.day().month(.abbreviated).year().hour().minute())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(Format.distance(walk.distance))
                    .font(.headline)
                Text(Format.duration(walk.duration))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.down")
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }

    /// Mapa pequeño: el camino sugerido en azul y lo caminado en naranja encima.
    /// Solo se crea al desplegar, así la lista no carga un mapa por card.
    @ViewBuilder
    private var map: some View {
        let track = walk.track
        let suggested = suggestedPath
        if track.count > 1 || suggested.count > 1 {
            Map(initialPosition: .automatic) {
                if suggested.count > 1 {
                    SuggestedPath(coordinates: suggested)
                }
                if track.count > 1 {
                    MapPolyline(coordinates: track)
                        .stroke(.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                }
                if let first = track.first ?? suggested.first {
                    Marker("Inicio", systemImage: "figure.walk", coordinate: first)
                        .tint(.green)
                }
                if let last = track.last ?? suggested.last {
                    Marker("Final", systemImage: "flag.checkered", coordinate: last)
                        .tint(.red)
                }
            }
            .mapControlVisibility(.hidden)
            .frame(height: 180)
            .clipShape(.rect(cornerRadius: 12))
            .accessibilityLabel(Text("Mapa del recorrido"))
        } else {
            Label("Sin ruta para mostrar en el mapa", systemImage: "map")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var details: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
            row("Fecha", walk.startDate.formatted(.dateTime.day().month(.twoDigits).year()))
            row("Hora inicial", walk.startDate.formatted(.dateTime.hour().minute().second()))
            row("Hora final", walk.endDate?.formatted(.dateTime.hour().minute().second()) ?? "—")
            row("Ubicación inicial", walk.startAddress)
            row("Ubicación final", walk.endAddress)
            row("Calorías quemadas", Format.calories(of: walk.pets, walking: walk.distance))
            row("Experiencia", String(localized: "+\(walk.experience) XP por mascota"))
            row("Ruta", walk.route?.name ?? String(localized: "No se usó una ruta personalizada"))
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }

    private func row(_ label: LocalizedStringResource, _ value: String) -> some View {
        GridRow(alignment: .top) {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
        }
    }
}
