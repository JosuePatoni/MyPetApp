import SwiftData
import SwiftUI

/// En un paseo hecho por un paseador, el dueño lo califica (1–5 estrellas) y deja un comentario.
struct WalkRatingSection: View {
    let walk: Walk

    @Environment(\.modelContext) private var modelContext
    @State private var stars: Int
    @State private var comment: String
    @State private var errorMessage: String?
    @State private var saved = false

    init(walk: Walk) {
        self.walk = walk
        _stars = State(initialValue: walk.rating ?? 0)
        _comment = State(initialValue: walk.comment)
    }

    var body: some View {
        if let walker = walk.walker {
            VStack(alignment: .leading, spacing: 8) {
                Text(walk.rating == nil ? "Califica a \(walker.username)" : "Tu calificación a \(walker.username)")
                    .font(.headline)
                StarRatingPicker(rating: $stars)
                TextField("Comentario sobre el paseo (opcional)", text: $comment, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button(walk.rating == nil ? "Enviar calificación" : "Actualizar calificación", action: save)
                        .buttonStyle(.borderedProminent)
                        .tint(MyPetPalette.teal)
                        .disabled(stars == 0)
                    if saved {
                        Label("Guardado", systemImage: "checkmark")
                            .foregroundStyle(MyPetPalette.teal)
                    }
                }
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func save() {
        walk.rate(stars: stars, comment: comment)
        do {
            try modelContext.save()
            errorMessage = nil
            saved = true
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
    }
}
