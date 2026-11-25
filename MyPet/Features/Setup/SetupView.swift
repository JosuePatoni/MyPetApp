import SwiftData
import SwiftUI

/// Configuración inicial tras el registro: elegir Dueño o Paseador con tarjetas grandes.
struct SetupView: View {
    let user: User

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SetupViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Configuración inicial")
                    .font(.largeTitle.bold())
                Text("¿Cómo usarás MyPet?")
                    .font(.title3.bold())
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(MyPetPalette.yellow, in: .rect(cornerRadius: 10))

                ForEach(UserRole.allCases) { role in
                    roleCard(role)
                }

                Text("Puedes ver tu tipo de usuario en tu perfil. Los recordatorios de paseo se configuran al agregar cada mascota.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                Button {
                    viewModel.finish(user: user, in: modelContext)
                } label: {
                    Text("Comenzar")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(MyPetPalette.teal)
                .buttonBorderShape(.roundedRectangle(radius: 14))
            }
            .padding(24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .background { PawBackground() }
    }

    private func roleCard(_ role: UserRole) -> some View {
        let isSelected = viewModel.role == role
        return Button {
            viewModel.role = role
        } label: {
            HStack(spacing: 16) {
                Image(systemName: role.symbolName)
                    .font(.system(size: 52))
                    .foregroundStyle(MyPetPalette.teal)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(role.title)
                        .font(.title2.bold())
                    Text(role.summary)
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(MyPetPalette.teal)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(.black)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? role.tint : MyPetPalette.mint.opacity(0.5), in: .rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(MyPetPalette.teal, lineWidth: isSelected ? 3 : 1.5)
            }
            .contentShape(.rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
