import Foundation
import SwiftData

/// Mensaje del chat con Loki. El historial se guarda por mascota y se borra con ella.
@Model
final class ChatMessage {
    var text: String
    var isFromLoki: Bool
    var date: Date
    var pet: Pet?

    init(text: String, isFromLoki: Bool, date: Date = .now) {
        self.text = text
        self.isFromLoki = isFromLoki
        self.date = date
    }
}
