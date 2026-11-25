import SwiftData
import SwiftUI

struct LoginView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = LoginViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Inicia sesión")
                        .font(.largeTitle.bold())
                        .padding(.top, 80)

                    FormField(title: "Usuario") {
                        TextField("Usuario", text: $viewModel.username)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    FormField(title: "Contraseña") {
                        SecureField("Contraseña", text: $viewModel.password)
                            .textContentType(.password)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button("Aceptar", action: login)
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.canSubmit)

                    VStack(spacing: 4) {
                        Text("¿No tienes una cuenta?")
                            .foregroundStyle(.secondary)
                        NavigationLink("Registrarme") {
                            RegisterView()
                        }
                    }
                }
                .padding()
                .frame(maxWidth: 500)
                .frame(maxWidth: .infinity)
            }
            .background { PawBackground() }
        }
    }

    private func login() {
        if let user = viewModel.login(with: AuthService(context: modelContext)) {
            session.signIn(user)
        }
    }
}

#Preview {
    LoginView()
        .environment(SessionStore())
        .modelContainer(for: User.self, inMemory: true)
}
