import SwiftData
import SwiftUI

struct RegisterView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = RegisterViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Regístrate")
                    .font(.largeTitle.bold())
                    .padding(.top, 40)

                FormField(title: "Usuario") {
                    TextField("Usuario", text: $viewModel.username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                FormField(title: "Correo electrónico") {
                    TextField("Correo electrónico", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                FormField(title: "Contraseña") {
                    SecureField("Contraseña", text: $viewModel.password)
                        .textContentType(.newPassword)
                }

                FormField(title: "Confirmar contraseña") {
                    SecureField("Confirmar contraseña", text: $viewModel.confirmPassword)
                        .textContentType(.newPassword)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button("Enviar", action: register)
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canSubmit)
            }
            .padding()
            .frame(maxWidth: 500)
            .frame(maxWidth: .infinity)
        }
        .background { PawBackground() }
    }

    private func register() {
        if let user = viewModel.register(with: AuthService(context: modelContext)) {
            session.signIn(user)
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView()
    }
    .environment(SessionStore())
    .modelContainer(for: User.self, inMemory: true)
}
