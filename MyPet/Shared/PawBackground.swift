import SwiftUI

struct PawBackground: View {
    private let paws: [(x: CGFloat, y: CGFloat, angle: Double, color: Color)] = [
        (0.12, 0.07, -28, MyPetPalette.apricot),
        (0.29, 0.04, -12, MyPetPalette.yellow),
        (0.47, 0.06,  12, MyPetPalette.turquoise),
        (0.65, 0.10,  27, MyPetPalette.mint),
        (0.38, 0.94, -24, MyPetPalette.mint),
        (0.55, 0.91, -12, MyPetPalette.turquoise),
        (0.72, 0.87,  12, MyPetPalette.yellow),
        (0.88, 0.82,  25, MyPetPalette.apricot)
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(uiColor: .systemBackground)

                ForEach(paws.indices, id: \.self) { index in
                    let paw = paws[index]

                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 29, weight: .semibold))
                        .foregroundStyle(paw.color)
                        .opacity(0.72)
                        .rotationEffect(.degrees(paw.angle))
                        .position(
                            x: geometry.size.width * paw.x,
                            y: geometry.size.height * paw.y
                        )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
