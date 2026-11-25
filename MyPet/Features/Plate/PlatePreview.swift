import SwiftUI

/// Vista previa de la placa con acabado metálico: borde biselado, brillo cepillado y texto grabado.
struct PlatePreview: View {
    let shape: PlateShape
    let color: PlateColor
    let text: String
    var size = 180.0

    var body: some View {
        let symbol = Image(systemName: shape.symbolName)
            .resizable()
            .scaledToFit()
        let shades = color.shades
        let area = shape.textArea

        ZStack {
            // Bisel: la forma completa con luz arriba-izquierda y sombra abajo-derecha; queda como borde.
            symbol
                .foregroundStyle(
                    LinearGradient(colors: [shades.light, shades.dark], startPoint: .topLeading, endPoint: .bottomTrailing)
                )

            // Cara de la placa, un poco más chica que el bisel.
            // ponytail: el bisel escala desde el centro; en el corazón queda algo más grueso abajo
            ZStack {
                // Metal cepillado: franjas claras y oscuras alrededor del centro.
                AngularGradient(
                    colors: [shades.light, shades.base, shades.dark, shades.base, shades.light, shades.base, shades.dark, shades.base, shades.light],
                    center: .center
                )
                // Reflejo diagonal de luz.
                LinearGradient(
                    colors: [.white.opacity(0.55), .clear, .clear, .black.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .mask(symbol.scaleEffect(0.9))

            // Texto grabado: oscuro, con sombra interior y un filo de luz debajo.
            Text(text)
                .font(.headline.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(shades.dark.shadow(.inner(color: .black.opacity(0.6), radius: 1, y: 1)))
                .shadow(color: .white.opacity(0.6), radius: 0, y: 1)
                .lineLimit(4)
                .minimumScaleFactor(0.3)
                .frame(width: size * area.width, height: size * area.height)
                .offset(y: size * area.offsetY)
        }
        .frame(width: size, height: size)
        .compositingGroup()
        .shadow(color: .black.opacity(0.35), radius: 8, x: 2, y: 6)
    }
}
