import SwiftUI

/// Foto real de la mascota o, si no tiene, el icono de su especie.
struct PetPhoto: View {
    let data: Data?
    let species: Species

    var body: some View {
        // ponytail: decodifica en cada render (fotos ≤ 800 px); cachear si el carrusel se siente lento
        if let data, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: species.symbolName)
                .resizable()
                .scaledToFit()
                .padding(24)
                .foregroundStyle(.tint)
        }
    }
}
