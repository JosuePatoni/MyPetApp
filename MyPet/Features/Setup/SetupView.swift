import SwiftData
import SwiftUI

/// Configuración inicial tras el registro.
struct SetupView: View {
    let user: User

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SetupViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Tipo de usuario", selection: $viewModel.role) {
                        ForEach(UserRole.allCases) { role in
                            Text(role.title).tag(role)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("¿Cómo usarás MyPet?")
                } footer: {
                    Text("Los recordatorios de paseo se configuran al agregar cada mascota.")
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Configuración inicial")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Comenzar") {
                        viewModel.finish(user: user, in: modelContext)
                    }
                }
            }
        }
    }
}
