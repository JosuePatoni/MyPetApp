import SwiftUI

struct HomeTile: View {
    let title: LocalizedStringKey
    let systemImage: String

    var fill: Color = MyPetPalette.mint
    var isHorizontal = false

    var body: some View {
        Group {
            if isHorizontal {
                HStack(spacing: 12) {
                    icon
                    Text(title)
                }
            } else {
                VStack(spacing: 10) {
                    icon
                    Text(title)
                }
            }
        }
        .font(.headline)
        .foregroundStyle(.black)
        .multilineTextAlignment(.center)
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: isHorizontal ? 64 : 106)
        .background(fill, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(MyPetPalette.teal, lineWidth: 2)
                .allowsHitTesting(false)
        }
        .contentShape(RoundedRectangle(cornerRadius: 20))
    }

    private var icon: some View {
        Image(systemName: systemImage)
            .font(.title.weight(.semibold))
            .foregroundStyle(MyPetPalette.teal)
            .accessibilityHidden(true)
    }
}
