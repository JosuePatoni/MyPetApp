import SwiftUI

/// Huellas decorativas de fondo para las pantallas de acceso.
struct PawBackground: View {
    private let paws: [(x: Double, y: Double, angle: Double)] = [
        (0.15, 0.08, -20), (0.35, 0.05, 15), (0.55, 0.10, -10), (0.10, 0.18, 25),
        (0.70, 0.75, -15), (0.85, 0.82, 20), (0.45, 0.88, -25), (0.20, 0.92, 10),
    ]

    var body: some View {
        GeometryReader { proxy in
            ForEach(paws.indices, id: \.self) { index in
                let paw = paws[index]
                Image(systemName: "pawprint.fill")
                    .font(.title)
                    .foregroundStyle(Color.accentColor.opacity(0.18))
                    .rotationEffect(.degrees(paw.angle))
                    .position(x: proxy.size.width * paw.x, y: proxy.size.height * paw.y)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
