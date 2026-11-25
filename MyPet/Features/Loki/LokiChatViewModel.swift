import Foundation
import Observation
import SwiftData

/// Chat con Loki (Gemini). El historial se guarda por mascota en SwiftData.
@MainActor
@Observable
final class LokiChatViewModel {
    /// Mensajes que se reenvían a Gemini como contexto de la conversación.
    // ponytail: ventana fija de 40 mensajes; resumir los anteriores si las conversaciones se hacen muy largas
    static let historyLimit = 40

    var draft = ""
    private(set) var isSending = false
    var errorMessage: String?

    var hasAPIKey: Bool { Secrets.geminiAPIKey != nil }

    func messages(of pet: Pet) -> [ChatMessage] {
        pet.chatMessages.sorted { $0.date < $1.date }
    }

    /// Al abrir un chat vacío, Loki saluda ("mreow ola soy loki…").
    func greetIfNeeded(user: User, pet: Pet, in context: ModelContext) async {
        guard pet.chatMessages.isEmpty, !isSending else { return }
        await requestReply(user: user, pet: pet, in: context)
    }

    func send(user: User, pet: Pet, in context: ModelContext) async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }
        draft = ""
        let message = ChatMessage(text: text, isFromLoki: false)
        context.insert(message)
        message.pet = pet
        await requestReply(user: user, pet: pet, in: context)
    }

    /// Vuelve a pedir respuesta al último mensaje (tras un error de red).
    func retry(user: User, pet: Pet, in context: ModelContext) async {
        await requestReply(user: user, pet: pet, in: context)
    }

    func clearHistory(of pet: Pet, in context: ModelContext) {
        for message in pet.chatMessages {
            context.delete(message)
        }
        pet.chatMessages.removeAll()
        errorMessage = nil
        try? context.save()
    }

    private func requestReply(user: User, pet: Pet, in context: ModelContext) async {
        guard let apiKey = Secrets.geminiAPIKey else {
            errorMessage = GeminiClient.GeminiError.missingAPIKey.errorDescription
            return
        }
        isSending = true
        errorMessage = nil
        defer { isSending = false }

        let history = messages(of: pet).suffix(Self.historyLimit).map {
            GeminiClient.Turn(role: $0.isFromLoki ? .model : .user, text: $0.text)
        }
        // El turno de apertura va siempre primero: Gemini exige que el historial empiece con "user".
        let turns = [GeminiClient.Turn(role: .user, text: LokiPrompt.openingTurn)] + history
        let system = LokiPrompt.systemInstruction(contextJSON: LokiContext(user: user, pet: pet).json())

        do {
            let reply = try await GeminiClient(apiKey: apiKey).generate(systemInstruction: system, turns: turns)
            let message = ChatMessage(text: reply, isFromLoki: true)
            context.insert(message)
            message.pet = pet
            try context.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
