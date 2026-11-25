import SwiftUI

/// Perfil: foto, km recorridos, editar perfil, recompensas y cerrar sesión.
struct ProfileView: View {
    let user: User

    @Environment(SessionStore.self) private var session
    @State private var isEditing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                UserPhoto(data: user.photoData)
                    .frame(width: 140, height: 140)
                    .clipShape(.circle)
                    .accessibilityHidden(true)

                VStack(spacing: 4) {
                    Text(user.username)
                        .font(.title.bold())
                    Text("Km recorridos: \(Format.distance(user.walkedDistance))")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    Button {
                        isEditing = true
                    } label: {
                        Label("Editar perfil", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }

                    NavigationLink(value: HomeDestination.rewards) {
                        Label("Recompensas", systemImage: "medal")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive, action: session.signOut)
                    .padding(.top, 24)
            }
            .padding()
        }
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isEditing) {
            EditProfileView(user: user)
        }
    }
}
