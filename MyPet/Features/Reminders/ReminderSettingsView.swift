import SwiftData
import SwiftUI

struct ReminderSettingsView: View {
    let pet: Pet

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ReminderSettingsViewModel

    init(pet: Pet) {
        self.pet = pet
        _viewModel = State(initialValue: ReminderSettingsViewModel(pet: pet))
    }

    var body: some View {
        Form {
            ReminderFields(draft: $viewModel.draft)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .navigationTitle("Paseos de \(pet.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Guardar") {
                if viewModel.save(pet: pet, in: modelContext) {
                    dismiss()
                }
            }
        }
    }
}
