import SwiftData
import SwiftUI

/// Card de la mascota: foto, nivel, barra de XP, especie, raza, peso, paseos, QR y placa.
struct PetDetailView: View {
    let pet: Pet
    let owner: User

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var isConfirmingDelete = false

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
                    PetStat(value: Text(pet.breed), label: "Raza")
                    Divider()
                    PetStat(value: weightText, label: "Peso")
                }
                .fixedSize(horizontal: false, vertical: true)

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

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Identificación")
                        .font(.headline)
                    NavigationLink(value: HomeDestination.petQR(pet.uuid)) {
                        Label("Generar QR para imprimir", systemImage: "qrcode")
                    }
                    NavigationLink(value: HomeDestination.petPlate(pet.uuid)) {
                        Label("Solicitar placa personalizada ($100 MXN)", systemImage: "tag")
                    }
                    if let date = pet.plateOrderDate {
                        Text("Placa solicitada el \(date, format: .dateTime.day().month().year())")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
        .toolbar {
            Menu("Opciones", systemImage: "ellipsis.circle") {
                Button("Editar", systemImage: "pencil") { isEditing = true }
                Button("Eliminar", systemImage: "trash", role: .destructive) { isConfirmingDelete = true }
            }
        }
        .sheet(isPresented: $isEditing) {
            PetFormView(owner: owner, pet: pet)
        }
        .confirmationDialog(
            "¿Eliminar a \(pet.name)?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive, action: deletePet)
        } message: {
            Text("Se borran también sus paseos y su recordatorio. Los logros conseguidos se conservan.")
        }
    }

    /// Primero sale de la card y luego borra: así ninguna vista lee la mascota ya eliminada.
    private func deletePet() {
        let notificationKey = pet.reminder?.notificationKey
        dismiss()
        owner.pets.removeAll { $0.uuid == pet.uuid }
        modelContext.delete(pet)
        do {
            try modelContext.save()
            if let notificationKey {
                Task { await ReminderScheduler.cancel(notificationKey: notificationKey) }
            }
        } catch {
            modelContext.rollback()
        }
    }

    private var weightText: Text {
        if let weight = pet.weight {
            Text("\(weight, format: .number.precision(.fractionLength(0...1))) kg")
        } else {
            Text("—")
        }
    }
}
