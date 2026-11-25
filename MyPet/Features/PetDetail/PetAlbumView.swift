import SwiftUI

struct PetAlbumView: View {
    let pet: Pet
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var draft: Draft?
    @State private var pendingDelete: PetAlbumStore.Photo?
    @State private var error = ""
    private let store = PetAlbumStore.shared

    private struct Draft: Identifiable {
        let id: UUID
        let photo: PetAlbumStore.Photo?
    }

    var body: some View {
        ScrollView {
            if let album = try? store.read(pet.uuid) {
                if album.photos.isEmpty {
                    ContentUnavailableView("Álbum vacío", systemImage: "photo.on.rectangle",
                                           description: Text("Toca + para añadir la primera foto."))
                } else {
                    let cover = store.currentCover(album, pet: pet)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .top),
                                             count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 22) {
                        ForEach(album.photos) { photo in
                            VStack(spacing: 8) {
                                Color(uiColor: .secondarySystemBackground)
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay {
                                        if let data = try? store.image(photo, petID: pet.uuid),
                                           let image = UIImage(data: data) {
                                            Image(uiImage: image).resizable().scaledToFill()
                                        } else { Image(systemName: "photo") }
                                    }
                                    .clipShape(.rect(cornerRadius: 16))
                                Text(photo.title).font(.headline).multilineTextAlignment(.center)
                                ViewThatFits(in: .horizontal) {
                                    HStack { actions(photo) }
                                    VStack { actions(photo) }
                                }
                                if cover == photo.id {
                                    Label("Foto de perfil", systemImage: "checkmark.circle.fill").font(.caption)
                                } else {
                                    Button("Establecer como foto de \(pet.name)") {
                                        do {
                                            try store.save(id: photo.id, title: photo.title,
                                                           newJPEG: nil, makeCover: true, pet: pet)
                                        } catch { self.error = error.localizedDescription }
                                    }
                                    .font(.subheadline).multilineTextAlignment(.center)
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView("No se pudo leer el álbum", systemImage: "exclamationmark.triangle")
            }
        }
        .navigationTitle("Álbum de \(pet.name)")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, alignment: .trailing) {
            Button { draft = Draft(id: UUID(), photo: nil) } label: {
                Image(systemName: "plus").font(.title2.bold()).frame(width: 54, height: 54)
                    .foregroundStyle(.white).background(MyPetPalette.teal, in: .circle)
            }
            .accessibilityLabel("Nueva foto").padding(.trailing).padding(.bottom, 4)
        }
        .sheet(item: $draft) { draft in
            AlbumPhotoEditor(pet: pet, id: draft.id, photo: draft.photo)
        }
        .confirmationDialog("¿Eliminar la foto?", isPresented: Binding(
            get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }
        ), presenting: pendingDelete) { photo in
            Button("Eliminar", role: .destructive) {
                do { try store.delete(photo, petID: pet.uuid) }
                catch { self.error = error.localizedDescription }
            }
        } message: { photo in Text(photo.title) }
        .alert("No se pudo completar la acción", isPresented: Binding(
            get: { !error.isEmpty }, set: { if !$0 { error = "" } }
        )) { Button("Aceptar") {} } message: { Text(error) }
    }

    @ViewBuilder private func actions(_ photo: PetAlbumStore.Photo) -> some View {
        Button("Editar") { draft = Draft(id: photo.id, photo: photo) }.buttonStyle(.bordered)
        Button("Eliminar", role: .destructive) { pendingDelete = photo }.buttonStyle(.bordered)
    }
}
