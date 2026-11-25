import AVFoundation
import PhotosUI
import SwiftUI

struct AlbumPhotoEditor: View {
    let pet: Pet
    let id: UUID
    let photo: PetAlbumStore.Photo?
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var isCover: Bool
    @State private var jpeg: Data?
    @State private var selection: PhotosPickerItem?
    @State private var loading = false
    @State private var cameraOpen = false
    @State private var error = ""

    init(pet: Pet, id: UUID, photo: PetAlbumStore.Photo?) {
        self.pet = pet
        self.id = id
        self.photo = photo
        _title = State(initialValue: photo?.title ?? "")
        let store = PetAlbumStore.shared
        let album = try? store.read(pet.uuid)
        _isCover = State(initialValue: album.map { store.currentCover($0, pet: pet) == id } ?? false)
    }

    private var preview: Data? {
        jpeg ?? photo.flatMap { try? PetAlbumStore.shared.image($0, petID: pet.uuid) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Button {
                        Task {
                            if await AVCaptureDevice.requestAccess(for: .video) { cameraOpen = true }
                            else { error = "Permite el acceso a la cámara en Configuración o elige una foto." }
                        }
                    } label: {
                        Color.clear.aspectRatio(1.32, contentMode: .fit)
                            .background(MyPetPalette.mint)
                            .overlay {
                                if let preview, let image = UIImage(data: preview) {
                                    Image(uiImage: image).resizable().scaledToFit()
                                } else {
                                    VStack(spacing: 12) {
                                        Image(systemName: "camera").font(.largeTitle)
                                        Text("Tomar foto").font(.headline)
                                    }.foregroundStyle(MyPetPalette.teal)
                                }
                            }
                            .clipShape(.rect(cornerRadius: 20))
                    }
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera) || loading)
                    .accessibilityLabel("Tomar foto")

                    PhotosPicker(selection: $selection, matching: .images) {
                        Label("Elegir de la fototeca", systemImage: "photo.on.rectangle")
                    }
                    FormField(title: "Título") { TextField("Título de la foto", text: $title) }
                    Toggle("Establecer como foto de \(pet.name)", isOn: $isCover)
                    if loading { ProgressView("Cargando foto…") }
                    if !error.isEmpty { Text(error).font(.footnote).foregroundStyle(.red) }
                    HStack {
                        Button("Cancelar") { dismiss() }.buttonStyle(.bordered)
                        Spacer()
                        Button("Aceptar", action: save).buttonStyle(.borderedProminent)
                            .disabled(loading || (photo == nil && jpeg == nil) || cleanTitle.isEmpty)
                    }
                    .controlSize(.large)
                }
                .padding(20).frame(maxWidth: 560).frame(maxWidth: .infinity)
            }
            .navigationTitle(photo == nil ? "Nueva foto" : "Editar foto")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: selection) {
                guard let selection else { return }
                loading = true
                defer { if !Task.isCancelled { loading = false } }
                do {
                    guard let data = try await selection.loadTransferable(type: Data.self),
                          let result = ImageDownscaler.jpegData(from: data) else {
                        throw CocoaError(.fileReadCorruptFile)
                    }
                    try Task.checkCancellation()
                    jpeg = result
                    error = ""
                } catch {
                    if !Task.isCancelled { self.error = error.localizedDescription }
                }
            }
            .fullScreenCover(isPresented: $cameraOpen) {
                CameraCapture { image in
                    cameraOpen = false
                    guard let image else { return }
                    if let data = image.jpegData(compressionQuality: 0.9),
                       let result = ImageDownscaler.jpegData(from: data) { jpeg = result; error = "" }
                    else { error = "No se pudo procesar la foto." }
                }.ignoresSafeArea()
            }
        }
    }

    private var cleanTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func save() {
        do {
            try PetAlbumStore.shared.save(id: id, title: cleanTitle, newJPEG: jpeg, makeCover: isCover, pet: pet)
            dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
