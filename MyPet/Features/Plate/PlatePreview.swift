import SwiftUI

/// Vista previa de la placa: la forma con un degradado vertical simple y el texto encima.
struct PlatePreview: View {
    let shape: PlateShape
    let color: PlateColor
    let text: String
    var size = 180.0

    var body: some View {
        let shades = color.shades
        let area = shape.textArea

        Image(systemName: shape.symbolName)
            .resizable()
            .scaledToFit()
            .foregroundStyle(LinearGradient(colors: [shades.light, shades.base], startPoint: .top, endPoint: .bottom))
            .frame(width: size, height: size)
            .overlay {
                Text(text)
                    .font(.headline.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(shades.dark)
                    .lineLimit(4)
                    .minimumScaleFactor(0.3)
                    .frame(width: size * area.width, height: size * area.height)
                    .offset(y: size * area.offsetY)
            }
    }
}
