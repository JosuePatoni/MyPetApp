import MapKit
import SwiftUI

/// Card del historial con los datos de la tabla `Paseo` y el mapa de su trazo.
struct WalkCard: View {
    let walk: Walk

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            let track = walk.track
            if track.count > 1 {
                // ponytail: un mapa por card; con cientos de paseos usar MKMapSnapshotter y cachear la imagen
                Map(initialPosition: .automatic, interactionModes: []) {
                    if let route = walk.route {
                        MapPolyline(coordinates: route.coordinates)
                            .stroke(.blue.opacity(0.5), lineWidth: 5)
                    }
                    MapPolyline(coordinates: track)
                        .stroke(.orange, lineWidth: 4)
                }
                .frame(height: 160)
                .clipShape(.rect(cornerRadius: 12))
                .accessibilityHidden(true)
            }

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                row("Mascota", walk.pets.isEmpty ? String(localized: "Mascota eliminada") : walk.pets.map(\.name).formatted(.list(type: .and)))
                row("Fecha", walk.startDate.formatted(.dateTime.day().month(.twoDigits).year()))
                row("Hora inicial", walk.startDate.formatted(.dateTime.hour().minute().second()))
                row("Hora final", walk.endDate?.formatted(.dateTime.hour().minute().second()) ?? "—")
                row("Ubicación inicial", walk.startAddress)
                row("Ubicación final", walk.endAddress)
                row("Distancia", Format.distance(walk.distance))
                row("Duración", Format.duration(walk.duration))
                row("Calorías quemadas", Format.calories(of: walk.pets, walking: walk.distance))
                row("Experiencia", String(localized: "+\(walk.experience) XP por mascota"))
                row("Ruta", walk.route?.name ?? String(localized: "No se usó una ruta personalizada"))
            }
            .font(.subheadline)
        }
        .padding()
        .background(.fill.tertiary, in: .rect(cornerRadius: 16))
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
