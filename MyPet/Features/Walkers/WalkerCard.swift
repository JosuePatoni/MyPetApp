import SwiftUI

/// Card de paseador: foto, nombre, XP, cantidad de paseos y calificación.
struct WalkerCard: View {
    let walker: User
    let isSelected: Bool
    var fill = MyPetPalette.mint

    var body: some View {
        HStack(spacing: 14) {
            UserPhoto(data: walker.photoData)
                .frame(width: 56, height: 56)
                .background(MyPetPalette.turquoise.opacity(0.3), in: .circle)
                .clipShape(.circle)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(walker.username)
                        .font(.headline)
                    if walker.isDemo {
                        Text("Ejemplo")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(MyPetPalette.yellow, in: .capsule)
                    }
                }
                Text("\(walker.walkerExperience) XP · ^[\(walker.walkerWalkCount) paseo](inflect: true)")
                    .font(.subheadline)
                StarRatingLabel(average: walker.averageRating, count: walker.ratingCount)
                    .font(.caption)
            }

            Spacer(minLength: 0)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(MyPetPalette.teal)
                .accessibilityHidden(true)
        }
        .foregroundStyle(.black)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(fill, in: .rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(MyPetPalette.teal, lineWidth: isSelected ? 3 : 1.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
