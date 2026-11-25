import PhotosUI
import SwiftData
import SwiftUI

/// Alta de mascota o, con `pet`, edición de sus datos.
struct PetFormView: View {
    let owner: User

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PetFormViewModel

    init(owner: User, pet: Pet? = nil) {
        self.owner = owner
        _viewModel = State(initialValue: PetFormViewModel(pet: pet))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker(selection: $viewModel.photoItem, matching: .images) {
                        VStack(spacing: 8) {
                            PetPhoto(data: viewModel.photoData, species: viewModel.species)
                                .frame(width: 120, height: 120)
                                .background(.fill.tertiary)
                                .clipShape(.circle)
                            Text(viewModel.photoData == nil ? "Elegir foto" : "Cambiar foto")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .onChange(of: viewModel.photoItem) {
                        Task { await viewModel.loadPhoto() }
                    }
                }

                TextField("Nombre", text: $viewModel.name)

                Picker("Tipo de mascota", selection: $viewModel.species) {
                    ForEach(Species.allCases) { species in
                        Label {
                            Text(species.title)
                        } icon: {
                            Image(systemName: species.symbolName)
                        }
                        .tag(species)
                    }
                }
                .onChange(of: viewModel.species) {
                    viewModel.breed = viewModel.species.breeds[0]
                }

                Picker("Raza", selection: $viewModel.breed) {
                    ForEach(viewModel.species.breeds, id: \.self) { breed in
                        Text(breed).tag(breed)
                    }
                }

                DatePicker(
                    "Fecha de nacimiento",
                    selection: $viewModel.birthDate,
                    in: ...Date.now,
                    displayedComponents: .date
                )

                TextField("Peso (kg)", value: $viewModel.weight, format: .number)
                    .keyboardType(.decimalPad)

                if !viewModel.isEditing {
                    Section("Recordatorio de paseo") {
                        ReminderFields(draft: $viewModel.reminder)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle(viewModel.isEditing ? "Editar mascota" : "Nueva mascota")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar", action: save)
                        .disabled(!viewModel.canSave)
                }
            }
        }
    }

    private func save() {
        if viewModel.save(owner: owner, in: modelContext) {
            dismiss()
        }
    }
}
