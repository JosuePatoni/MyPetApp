import SwiftUI

/// Card de la mascota: foto, nivel, barra de XP, especie, raza, peso y paseos.
struct PetDetailView: View {
    let pet: Pet

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PetPhoto(data: pet.photoData, species: pet.species)
                    .frame(width: 200, height: 200)
                    .background(.fill.tertiary)
                    .clipShape(.circle)
                    .overlay { Circle().stroke(.white, lineWidth: 6) }
                    .shadow(radius: 8)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text(pet.name)
                        .font(.largeTitle.bold())
                    Text("NV. \(pet.level)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 4)
                        .background(pet.species.tint, in: .capsule)
                }

                VStack(spacing: 6) {
                    ProgressView(value: Double(pet.experienceInLevel), total: Double(Pet.experiencePerLevel))
                        .tint(pet.species.tint)
                    HStack {
                        Text("\(pet.experienceInLevel) / \(Pet.experiencePerLevel) XP")
                        Spacer()
                        Text("Total: \(pet.experience) XP")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)

                Divider()

                HStack {
                    PetStat(value: Text(pet.species.title), label: "Especie")
                    Divider()
                    PetStat(value: Text(pet.breed), label: pet.species.breedTitle)
                    Divider()
                    PetStat(value: weightText, label: "Peso")
                }
                .fixedSize(horizontal: false, vertical: true)

                if pet.species.canBeWalked {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Paseos")
                            .font(.headline)
                        if let reminder = pet.reminder {
                            ReminderSummary(reminder: reminder)
                        } else {
                            Text("Sin recordatorio")
                                .foregroundStyle(.secondary)
                        }
                        NavigationLink("Editar recordatorio", value: HomeDestination.petReminder(pet.uuid))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(24)
            .background(.background, in: .rect(cornerRadius: 32))
            .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
            .padding()
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .background {
            LinearGradient(
                colors: [pet.species.tint.opacity(0.6), pet.species.tint.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var weightText: Text {
        if let weight = pet.weight {
            Text("\(weight, format: .number.precision(.fractionLength(0...1))) kg")
        } else {
            Text("—")
        }
    }
}
