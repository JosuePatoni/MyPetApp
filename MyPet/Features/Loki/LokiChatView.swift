import SwiftData
import SwiftUI

/// Chat con Loki, el gato asistente de cuidado de perros y gatos.
/// Desde el Home se elige la mascota arriba; desde la card de mascota llega fija.
struct LokiChatView: View {
    let user: User

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = LokiChatViewModel()
    @State private var petID: UUID?
    @State private var isConfirmingClear = false
    @FocusState private var isInputFocused: Bool

    /// `petID` fijo (desde la card) oculta el selector de mascota.
    private let isPetFixed: Bool

    init(user: User, petID: UUID?) {
        self.user = user
        isPetFixed = petID != nil
        _petID = State(initialValue: petID)
    }

    private var pets: [Pet] {
        user.pets.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private var pet: Pet? {
        pets.first { $0.uuid == petID } ?? pets.first
    }

    var body: some View {
        Group {
            if !viewModel.hasAPIKey {
                ContentUnavailableView(
                    "Loki está dormido",
                    systemImage: "key.slash",
                    description: Text("Falta la API key de Gemini. Copia Secrets.example.plist a MyPet/Secrets.plist y pega tu key.")
                )
            } else if let pet {
                chat(for: pet)
            } else {
                ContentUnavailableView(
                    "Loki necesita una mascota",
                    systemImage: "pawprint",
                    description: Text("Agrega un perro o un gato para platicar con Loki sobre su cuidado.")
                )
            }
        }
        .navigationTitle("Loki")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let pet, !pet.chatMessages.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Borrar conversación", systemImage: "trash") { isConfirmingClear = true }
                }
            }
        }
        .confirmationDialog("¿Borrar la conversación con Loki?", isPresented: $isConfirmingClear, titleVisibility: .visible) {
            Button("Borrar", role: .destructive) {
                if let pet {
                    viewModel.clearHistory(of: pet, in: modelContext)
                    Task { await viewModel.greetIfNeeded(user: user, pet: pet, in: modelContext) }
                }
            }
        }
    }

    private func chat(for pet: Pet) -> some View {
        VStack(spacing: 0) {
            if !isPetFixed && pets.count > 1 {
                Picker("Mascota", selection: Binding(get: { pet.uuid }, set: { petID = $0 })) {
                    ForEach(pets) { pet in
                        Text(pet.name).tag(pet.uuid)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top])
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages(of: pet)) { message in
                            LokiMessageBubble(message: message)
                                .id(message.persistentModelID)
                        }
                        if viewModel.isSending {
                            HStack {
                                ProgressView()
                                Text("Loki está escribiendo…")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .id("typing")
                        }
                        if let errorMessage = viewModel.errorMessage {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(errorMessage)
                                    .foregroundStyle(.red)
                                Button("Reintentar", systemImage: "arrow.clockwise") {
                                    Task { await viewModel.retry(user: user, pet: pet, in: modelContext) }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                }
                .onChange(of: pet.chatMessages.count) {
                    if let last = viewModel.messages(of: pet).last {
                        withAnimation { proxy.scrollTo(last.persistentModelID) }
                    }
                }
                .onChange(of: viewModel.isSending) {
                    if viewModel.isSending { withAnimation { proxy.scrollTo("typing") } }
                }
            }

            Text("Loki da orientación general y no sustituye al veterinario.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            HStack(alignment: .bottom, spacing: 8) {
                TextField("Pregúntale a Loki sobre \(pet.name)…", text: $viewModel.draft, axis: .vertical)
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .padding(10)
                    .background(Color(uiColor: .systemBackground), in: .rect(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(MyPetPalette.teal, lineWidth: 1.5)
                    }
                Button("Enviar", systemImage: "arrow.up.circle.fill") {
                    Task { await viewModel.send(user: user, pet: pet, in: modelContext) }
                }
                .labelStyle(.iconOnly)
                .font(.system(size: 34))
                .foregroundStyle(MyPetPalette.teal)
                .disabled(viewModel.isSending || viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        // Cambiar de mascota abre su propia conversación; si está vacía, Loki saluda.
        .task(id: pet.uuid) {
            viewModel.errorMessage = nil
            await viewModel.greetIfNeeded(user: user, pet: pet, in: modelContext)
        }
    }
}
