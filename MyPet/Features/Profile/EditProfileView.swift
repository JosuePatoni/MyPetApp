import PhotosUI
import SwiftData
import SwiftUI

struct EditProfileView: View {
    let user: User

    @Environment(SessionStore.self) private var session
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EditProfileViewModel

    @State private var loadingPhoto = false

    init(user: User) {
        self.user = user
        _viewModel = State(initialValue: EditProfileViewModel(user: user))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PhotosPicker(selection: $viewModel.photoItem, matching: .images) {
                        VStack(spacing: 8) {
                            UserPhoto(data: viewModel.photoData)
                                .frame(width: 120, height: 120)
                                .background(MyPetPalette.mint, in: Circle())
                                .clipShape(.circle)
                                .overlay { Circle().strokeBorder(MyPetPalette.teal, lineWidth: 2) }
                            Text("Cambiar foto")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .onChange(of: viewModel.photoItem) {
                        loadingPhoto = true
                        Task {
                            await viewModel.loadPhoto()
                            loadingPhoto = false
                        }
                    }
                    .disabled(loadingPhoto)
                    if loadingPhoto { ProgressView("Cargando foto…") }

                    FormField(title: "Nombre de usuario") {
                        TextField("Nombre de usuario", text: $viewModel.username)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    Text("Cambiar contraseña").font(.title3.bold())
                        .foregroundStyle(.black).padding(.horizontal, 12).padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(MyPetPalette.yellow, in: .rect(cornerRadius: 10))
                    Text("Deja los campos vacíos para conservar tu contraseña.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    FormField(title: "Contraseña actual") {
                        SecureField("Contraseña actual", text: $viewModel.currentPassword)
                            .textContentType(.password)
                    }
                    FormField(title: "Nueva contraseña") {
                        SecureField("Nueva contraseña", text: $viewModel.newPassword)
                            .textContentType(.newPassword)
                    }
                    FormField(title: "Confirmar contraseña") {
                        SecureField("Confirmar contraseña", text: $viewModel.confirmPassword)
                            .textContentType(.newPassword)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                    HStack {
                        Button("Cancelar") { dismiss() }.buttonStyle(.bordered)
                        Spacer()
                        Button("Aceptar") {
                            if viewModel.save(user: user, auth: AuthService(context: modelContext), session: session) {
                                dismiss()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(loadingPhoto)
                    }
                    .controlSize(.large)
                }
                .padding(20).frame(maxWidth: 520).frame(maxWidth: .infinity)
            }
            .navigationTitle("Editar perfil")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
