import SwiftUI

/// Elegir de 1 a 5 estrellas tocándolas. Con VoiceOver se ajusta deslizando arriba/abajo.
struct StarRatingPicker: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { star in
                Button {
                    rating = star
                } label: {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundStyle(MyPetPalette.teal)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Calificación")
        .accessibilityValue(rating == 0 ? Text("Sin calificar") : Text("\(rating) de 5 estrellas"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: rating = min(rating + 1, 5)
            case .decrement: rating = max(rating - 1, 1)
            @unknown default: break
            }
        }
    }
}
