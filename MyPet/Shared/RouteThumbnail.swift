// MKMapSnapshotter.Snapshot aún no es Sendable; @preconcurrency evita errores de Swift 6 al recibirlo.
@preconcurrency import MapKit
import SwiftUI

/// Captura pequeña del mapa (imagen fija, no un `Map`) con el camino sugerido y lo caminado encima.
struct RouteThumbnail: View {
    let planned: [CLLocationCoordinate2D]
    let track: [CLLocationCoordinate2D]
    var size = CGSize(width: 64, height: 64)

    @Environment(\.colorScheme) private var colorScheme
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
            } else {
                Image(systemName: "map")
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.tint.opacity(0.15))
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(.rect(cornerRadius: 10))
        // ponytail: se genera cada vez que aparece la card; cachear la imagen en disco si la lista se siente lenta
        .task(id: colorScheme) {
            image = await Self.render(planned: planned, track: track, size: size, colorScheme: colorScheme)
        }
        .accessibilityHidden(true)
    }

    private static func render(
        planned: [CLLocationCoordinate2D],
        track: [CLLocationCoordinate2D],
        size: CGSize,
        colorScheme: ColorScheme
    ) async -> UIImage? {
        let all = planned + track
        guard all.count > 1 else { return nil }

        let bounds = MKPolyline(coordinates: all, count: all.count).boundingMapRect
        let options = MKMapSnapshotter.Options()
        // Margen para que la línea no toque los bordes; mínimo para paseos muy cortos.
        options.mapRect = bounds.insetBy(dx: -max(bounds.width * 0.2, 300), dy: -max(bounds.height * 0.2, 300))
        options.size = size
        options.pointOfInterestFilter = .excludingAll
        options.traitCollection = UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)
        guard let snapshot = try? await MKMapSnapshotter(options: options).start() else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = snapshot.image.scale
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            snapshot.image.draw(at: .zero)
            let cg = context.cgContext
            cg.setLineCap(.round)
            cg.setLineJoin(.round)

            func stroke(_ coordinates: [CLLocationCoordinate2D], width: CGFloat, color: UIColor) {
                guard let first = coordinates.first else { return }
                cg.beginPath()
                cg.move(to: snapshot.point(for: first))
                for coordinate in coordinates.dropFirst() {
                    cg.addLine(to: snapshot.point(for: coordinate))
                }
                cg.setLineWidth(width)
                cg.setStrokeColor(color.cgColor)
                cg.strokePath()
            }

            stroke(planned, width: 5, color: .white)
            stroke(planned, width: 3, color: .systemBlue)
            stroke(track, width: 2, color: .systemOrange)
        }
    }
}
