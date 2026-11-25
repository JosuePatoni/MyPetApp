import SwiftUI

/// Calificación de solo lectura: 5 estrellas (con medias) y el promedio, p. ej. "★★★★½ 4.6 (20)".
struct StarRatingLabel: View {
    let average: Double?
    var count: Int?

    var body: some View {
        if let average {
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: symbol(for: star, average: average))
                        .foregroundStyle(MyPetPalette.teal)
                }
                Text(average, format: .number.precision(.fractionLength(1)))
                    .fontWeight(.semibold)
                    .padding(.leading, 4)
                if let count {
                    Text("(\(count))")
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Calificación \(average, format: .number.precision(.fractionLength(1))) de 5"))
        } else {
            Text("Sin calificaciones")
                .foregroundStyle(.secondary)
        }
    }

    private func symbol(for star: Int, average: Double) -> String {
        if average >= Double(star) { return "star.fill" }
        if average >= Double(star) - 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }
}
