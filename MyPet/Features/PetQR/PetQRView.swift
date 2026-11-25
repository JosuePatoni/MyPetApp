import SwiftUI

/// Pide el contacto y muestra la hoja del QR lista para imprimir.
/// Dueño: dirección + teléfono. Paseador: solo su teléfono (no se imprime ninguna dirección).
struct PetQRView: View {
    let pet: Pet
    // Se edita directo en el usuario: SwiftData lo guarda solo y se reutiliza en otras mascotas y en la placa.
    @Bindable var owner: User

    private var isWalker: Bool { owner.role == .walker }

    private var hasContact: Bool {
        let hasPhone = owner.phone.filter(\.isNumber).count >= 10
        if isWalker { return hasPhone }
        return hasPhone && !owner.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section {
                if !isWalker {
                    TextField("Dirección", text: $owner.address, axis: .vertical)
                        .textContentType(.fullStreetAddress)
                        .lineLimit(2...4)
                }
                TextField("Teléfono de contacto", text: $owner.phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            } header: {
                Text(isWalker ? "Contacto del paseador" : "Contacto del dueño")
            } footer: {
                Text("Se imprime en la hoja y va dentro del QR. Teléfono a 10 dígitos.")
            }

            if hasContact {
                Section("Vista previa") {
                    let scale = 0.5
                    PetQRSheet(pet: pet, owner: owner)
                        .scaleEffect(scale)
                        .frame(width: PetQRSheet.pageSize.width * scale, height: PetQRSheet.pageSize.height * scale)
                        .frame(maxWidth: .infinity)
                }

                Button("Imprimir", systemImage: "printer", action: printSheet)
            }
        }
        .navigationTitle("QR de \(pet.name)")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// El diálogo de impresión de iOS también permite guardar el PDF en Archivos o compartirlo.
    private func printSheet() {
        let info = UIPrintInfo.printInfo()
        info.jobName = String(localized: "QR de \(pet.name)")
        info.outputType = .general
        let controller = UIPrintInteractionController.shared
        controller.printInfo = info
        controller.printingItem = PDFRenderer.data(for: PetQRSheet(pet: pet, owner: owner))
        _ = controller.present(animated: true)
    }
}
