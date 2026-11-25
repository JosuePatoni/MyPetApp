import SwiftData
import SwiftUI

/// Configuración inicial tras el registro: tipo de usuario y recordatorio de paseo.
struct SetupView: View {
    let user: User

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SetupViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("¿Cómo usarás MyPet?") {
                    Picker("Tipo de usuario", selection: $viewModel.role) {
                        ForEach(UserRole.allCases) { role in
                            Text(role.title).tag(role)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    ReminderFields(
                        isEnabled: $viewModel.isReminderEnabled,
                        intervalHours: $viewModel.intervalHours,
                        startTime: $viewModel.startTime
                    )
                } header: {
                    Text("Recordatorio de paseo")
                } footer: {
                    Text("Puedes cambiarlo después en Mis recordatorios.")
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
                        Task { await viewModel.finish(user: user, in: modelContext) }
                    }
                }
            }
        }
    }
}
