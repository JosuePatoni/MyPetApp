import SwiftUI

/// Carrusel circular de mascotas con flechas: después de la última vuelve a la primera.
struct PetCarousel: View {
    let pets: [Pet]
    @Binding var selection: Int
    let onAdd: () -> Void

    var body: some View {
        if pets.isEmpty {
            ContentUnavailableView {
                Label("Aún no tienes mascotas", systemImage: "pawprint")
            } description: {
                Text("Registra a tu primer amigo.")
            } actions: {
                Button("Agregar mascota", action: onAdd)
                    .buttonStyle(.borderedProminent)
            }
        } else {
            let index = min(selection, pets.count - 1)
            HStack {
                Button("Anterior", systemImage: "chevron.left") {
                    selection = (index - 1 + pets.count) % pets.count
                }
                .frame(minWidth: 44, minHeight: 44)
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .disabled(pets.count == 1)

                NavigationLink(value: HomeDestination.pet(pets[index].uuid)) {
                    PetCard(pet: pets[index])
                }
                .buttonStyle(.plain)
                .accessibilityHint("Abre la ficha de la mascota")
                .frame(maxWidth: .infinity)

                Button("Siguiente", systemImage: "chevron.right") {
                    selection = (index + 1) % pets.count
                }
                .frame(minWidth: 44, minHeight: 44)
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .disabled(pets.count == 1)
            }
            .labelStyle(.iconOnly)
            .font(.title2)
        }
    }
}
