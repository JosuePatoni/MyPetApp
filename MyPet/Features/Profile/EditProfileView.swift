import PhotosUI
import SwiftData
import SwiftUI

struct EditProfileView: View {
    let user: User

    @Environment(SessionStore.self) private var session
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EditProfileViewModel

    init(user: User) {
        self.user = user
        _viewModel = State(initialValue: EditProfileViewModel(user: user))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker(selection: $viewModel.photoItem, matching: .images) {
                        VStack(spacing: 8) {
                            UserPhoto(data: viewModel.photoData)
                                .frame(width: 120, height: 120)
                                .clipShape(.circle)
                            Text("Cambiar foto")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .onChange(of: viewModel.photoItem) {
                        Task { await viewModel.loadPhoto() }
                    }
                }

                Section("Nombre de usuario") {
                    TextField("Nombre de usuario", text: $viewModel.username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section {
                    SecureField("Contraseña actual", text: $viewModel.currentPassword)
                        .textContentType(.password)
                    SecureField("Nueva contraseña", text: $viewModel.newPassword)
                        .textContentType(.newPassword)
                    SecureField("Confirmar contraseña", text: $viewModel.confirmPassword)
                        .textContentType(.newPassword)
                } header: {
                    Text("Cambiar contraseña")
                } footer: {
                    Text("Déjala vacía para conservar tu contraseña actual.")
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Editar perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Aceptar") {
                        if viewModel.save(user: user, auth: AuthService(context: modelContext), session: session) {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
