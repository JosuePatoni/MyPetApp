import SwiftUI

struct ProfileView: View {
    let user: User

    @Environment(SessionStore.self) private var session
    @State private var isEditing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                UserPhoto(data: user.photoData)
                    .frame(width: 140, height: 140)
                    .background(MyPetPalette.mint, in: Circle())
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(MyPetPalette.teal, lineWidth: 2)
                    }
                    .accessibilityHidden(true)

                VStack(spacing: 6) {
                    Text(user.username)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    Text("Distancia recorrida: \(Format.distance(user.walkedDistance))")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 14) {
                    Button {
                        isEditing = true
                    } label: {
                        profileRow(
                            "Editar perfil",
                            systemImage: "pencil",
                            fill: MyPetPalette.yellow
                        )
                    }

                    NavigationLink(value: HomeDestination.rewards) {
                        profileRow(
                            "Recompensas",
                            systemImage: "ticket",
                            fill: MyPetPalette.turquoise
                        )
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 8)

                Button(
                    "Cerrar sesión",
                    systemImage: "rectangle.portrait.and.arrow.right",
                    role: .destructive,
                    action: session.signOut
                )
                .buttonStyle(.bordered)
                .controlSize(.large)
                .padding(.top, 20)
            }
            .padding(20)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Mi perfil")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isEditing) {
            EditProfileView(user: user)
        }
    }

    private func profileRow(
        _ title: LocalizedStringKey,
        systemImage: String,
        fill: Color
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(MyPetPalette.teal)
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(MyPetPalette.teal)
                .accessibilityHidden(true)
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
        .background(fill, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(MyPetPalette.teal, lineWidth: 2)
                .allowsHitTesting(false)
        }
        .contentShape(RoundedRectangle(cornerRadius: 18))
    }
}
