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

    var isWalking = false
    @State private var selectedWalk: Walk?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nivel \(pet.level)").font(.title.bold())
                        ProgressView(value: Double(pet.experienceInLevel), total: Double(Pet.experiencePerLevel))
                        Text("\(pet.experienceInLevel) / \(Pet.experiencePerLevel) XP").font(.subheadline)
                        Text("Total: \(pet.experience) XP").font(.caption).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    PetPhoto(data: PetAlbumStore.shared.portrait(of: pet), species: pet.species)
                        .frame(width: 104, height: 104).tint(MyPetPalette.teal)
                        .background(MyPetPalette.mint).clipShape(.rect(cornerRadius: 18))
                        .accessibilityHidden(true)
                }
                VStack(spacing: 0) {
                    stat("Especie", value: Text(pet.species.title))
                    stat("Edad", value: Text(age))
                    stat("Peso", value: weightText)
                    stat("Raza", value: Text(pet.breed.isEmpty ? "—" : pet.breed))
                }
                .clipShape(.rect(cornerRadius: 14))
                .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(MyPetPalette.teal) }

                Text("Condiciones médicas").font(.title3.bold())
                if pet.diseases.isEmpty {
                    Text("\(pet.name) no tiene condiciones registradas.").foregroundStyle(.secondary)
                } else {
                    ForEach(pet.diseases.sorted { $0.name < $1.name }) { disease in
                        Text(disease.name).font(.headline)
                        if !disease.details.isEmpty { Text(disease.details) }
                    }
                }

                NavigationLink {
                    PetAlbumView(pet: pet)
                } label: {
                    HStack {
                        Label("Álbum de fotos", systemImage: "photo.on.rectangle").font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right").accessibilityHidden(true)
                    }
                    .padding().foregroundStyle(.black)
                    .background(MyPetPalette.turquoise, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                Text("Paseos").font(.title3.bold())
                if pet.walks.isEmpty { Text("Aún no hay paseos registrados.").foregroundStyle(.secondary) }
                ForEach(pet.walks.sorted { $0.startDate > $1.startDate }) { walk in
                    Button {
                        selectedWalk = walk
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(walk.startDate, format: .dateTime.day().month().year()).font(.headline)
                                Text("Inicio: \(walk.startDate.formatted(date: .omitted, time: .standard))")
                                Text("Destino: \(walk.endAddress.isEmpty ? "—" : walk.endAddress)")
                            }
                            Spacer()
                            Image(systemName: "chevron.right").accessibilityHidden(true)
                        }
                        .padding().foregroundStyle(.black)
                        .background(MyPetPalette.apricot, in: .rect(cornerRadius: 14))
                    }.buttonStyle(.plain)
                }

                Text("Recordatorio").font(.title3.bold())
                if let reminder = pet.reminder { ReminderSummary(reminder: reminder) }
                else { Text("Sin recordatorio").foregroundStyle(.secondary) }
                NavigationLink("Editar recordatorio", value: HomeDestination.petReminder(pet.uuid))
                Text("Identificación").font(.title3.bold())
                NavigationLink(value: HomeDestination.petQR(pet.uuid)) {
                    Label("Generar QR para imprimir", systemImage: "qrcode")
                }
                NavigationLink(value: HomeDestination.petPlate(pet.uuid)) {
                    Label("Solicitar placa personalizada ($100 MXN)", systemImage: "tag")
                }
                if let date = pet.plateOrderDate {
                    Text("Placa solicitada el \(date, format: .dateTime.day().month().year())").font(.caption)
                }
                Button("Eliminar mascota", systemImage: "trash", role: .destructive) { isConfirmingDelete = true }
                    .disabled(isWalking)
                if isWalking { Text("Puedes eliminar la mascota cuando termine el paseo.").font(.caption) }
            }
            .padding(20).frame(maxWidth: 600).frame(maxWidth: .infinity)
        }
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Editar mascota", systemImage: "pencil.circle") { isEditing = true }
            }
        }
        .sheet(item: $selectedWalk) { walk in PetWalkDetail(walk: walk, pet: pet) }
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
            Text("Se borra también su recordatorio. Sus paseos y los logros conseguidos se conservan.")
        }
    }

    /// Primero sale de la card y luego borra: así ninguna vista lee la mascota ya eliminada.
    private func deletePet() {
        guard !isWalking else { return }
        let albumID = pet.uuid
        let notificationKey = pet.reminder?.notificationKey
        dismiss()
        owner.pets.removeAll { $0.uuid == pet.uuid }
        modelContext.delete(pet)
        do {
            try modelContext.save()
            try? PetAlbumStore.shared.removeAlbum(for: albumID)
            if let notificationKey {
                Task { await ReminderScheduler.cancel(notificationKey: notificationKey) }
            }
        } catch {
            modelContext.rollback()
        }
    }

    private var age: String {
        guard let birth = pet.birthDate, birth <= .now else { return "—" }
        let components = Calendar.current.dateComponents([.year, .month], from: birth, to: .now)
        if let years = components.year, years > 0 { return years == 1 ? "1 año" : "\(years) años" }
        let months = components.month ?? 0
        return months == 0 ? "Menos de un mes" : months == 1 ? "1 mes" : "\(months) meses"
    }

    private func stat(_ label: LocalizedStringKey, value: Text) -> some View {
        HStack(spacing: 0) {
            Text(label).bold().foregroundStyle(.black).padding(10)
                .frame(minWidth: 92, alignment: .leading).background(MyPetPalette.yellow)
            value.padding(.horizontal, 12)
            Spacer()
        }.overlay(alignment: .bottom) { Divider() }
        .accessibilityElement(children: .combine)
    }

    private var weightText: Text {
        if let weight = pet.weight {
            Text("\(weight, format: .number.precision(.fractionLength(0...1))) kg")
        } else {
            Text("—")
        }
    }
}
