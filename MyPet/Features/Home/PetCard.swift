import SwiftUI

struct PetCard: View {
    let pet: Pet

    var body: some View {
        VStack(spacing: 6) {
            PetPhoto(data: pet.photoData, species: pet.species)
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .tint(MyPetPalette.teal)
                .accessibilityHidden(true)

            Text(pet.name)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("Nivel \(pet.level) · \(pet.experience) XP")
                .font(.subheadline)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.black)
        .padding(14)
        .frame(maxWidth: 260)
        .background(MyPetPalette.mint, in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(MyPetPalette.teal, lineWidth: 2)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .combine)
    }
}
