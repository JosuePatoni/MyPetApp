import SwiftUI

struct PetCard: View {
    let pet: Pet

    var body: some View {
        VStack(spacing: 8) {
            PetPhoto(data: pet.photoData, species: pet.species)
                .frame(width: 180, height: 180)
                .background(.fill.tertiary)
                .clipShape(.rect(cornerRadius: 24))
                .accessibilityHidden(true)

            Text(pet.name)
                .font(.headline)
            Text("Nivel \(pet.level) · \(pet.experience) XP")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
