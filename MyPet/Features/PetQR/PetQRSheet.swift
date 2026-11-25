import SwiftUI

/// Hoja carta imprimible: foto, QR y datos de la mascota con el contacto del dueño.
struct PetQRSheet: View {
    static let pageSize = CGSize(width: 612, height: 792)

    let pet: Pet
    let owner: User

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("¡Hola! Me llamo \(pet.name)")
                    .font(.largeTitle.bold())
                Text("Si me encontraste, escanea el código o llama a mi familia.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 32) {
                PetPhoto(data: PetAlbumStore.shared.portrait(of: pet), species: pet.species)
                    .frame(width: 180, height: 180)
                    .background(pet.species.tint.opacity(0.15))
                    .clipShape(.circle)
                    .accessibilityHidden(true)

                // ponytail: el QR se genera en cada render (es barato); cachear si se nota al escribir
                if let qr = QRCode.image(for: qrText) {
                    Image(uiImage: qr)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 220, height: 220)
                        .accessibilityLabel("Código QR con los datos de \(pet.name)")
                }
            }

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                row("Especie", Text(pet.species.title))
                row("Raza", Text(pet.breed))
                row("Peso", Text(weightText))
                Divider()
                row("Dueño", Text(owner.username))
                row("Teléfono", Text(owner.phone))
                row("Dirección", Text(owner.address))
            }
            .font(.title3)

            Spacer(minLength: 0)

            Text("Generado con MyPet")
                .font(.footnote)
                .foregroundStyle(.gray)
        }
        .padding(48)
        .frame(width: Self.pageSize.width, height: Self.pageSize.height)
        .background(.white)
        .foregroundStyle(.black)
        .environment(\.colorScheme, .light)
    }

    /// Texto plano: cualquier cámara lo lee sin internet ni la app instalada.
    var qrText: String {
        [
            String(localized: "MyPet · \(pet.name)"),
            String(localized: "Especie: \(String(localized: pet.species.title))"),
            String(localized: "Raza: \(pet.breed)"),
            String(localized: "Peso: \(weightText)"),
            String(localized: "Dueño: \(owner.username)"),
            String(localized: "Teléfono: \(owner.phone)"),
            String(localized: "Dirección: \(owner.address)"),
        ].joined(separator: "\n")
    }

    private var weightText: String {
        pet.weight.map { "\($0.formatted(.number.precision(.fractionLength(0...1)))) kg" } ?? "—"
    }

    private func row(_ label: LocalizedStringResource, _ value: Text) -> some View {
        GridRow {
            Text(label)
                .bold()
            value
        }
    }
}
