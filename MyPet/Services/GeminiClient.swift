import Foundation

/// Cliente mínimo de la API REST de Gemini (`generateContent`), sin dependencias.
struct GeminiClient: Sendable {
    static let model = "gemini-3.1-flash-lite"

    struct Turn: Sendable {
        enum Role: String, Sendable {
            case user
            case model
        }

        let role: Role
        let text: String
    }

    enum GeminiError: LocalizedError {
        case missingAPIKey
        case server(String)
        case blocked
        case emptyResponse

        var errorDescription: String? {
            switch self {
            case .missingAPIKey: String(localized: "Falta la API key de Gemini (Secrets.plist).")
            case .server(let message): String(localized: "Gemini respondió con un error: \(message)")
            case .blocked: String(localized: "Loki no puede responder eso. Intenta con otra pregunta.")
            case .emptyResponse: String(localized: "Loki no respondió. Intenta de nuevo.")
            }
        }
    }

    let apiKey: String

    /// Envía las instrucciones de sistema y el historial; devuelve el texto de la respuesta.
    func generate(systemInstruction: String, turns: [Turn]) async throws -> String {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(Self.model):generateContent") else {
            throw GeminiError.emptyResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // En el encabezado, no en la URL, para que la key no quede en registros de URLs.
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONEncoder().encode(RequestBody(
            systemInstruction: Content(role: nil, parts: [Part(text: systemInstruction)]),
            contents: turns.map { Content(role: $0.role.rawValue, parts: [Part(text: $0.text)]) }
        ))

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let message = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error.message
            throw GeminiError.server(message ?? "HTTP \(http.statusCode)")
        }

        let body = try JSONDecoder().decode(ResponseBody.self, from: data)
        if body.promptFeedback?.blockReason != nil { throw GeminiError.blocked }
        guard let candidate = body.candidates?.first else { throw GeminiError.emptyResponse }
        if candidate.finishReason == "SAFETY" { throw GeminiError.blocked }
        // Se omiten las partes de razonamiento ("thought") si el modelo las incluye.
        let text = (candidate.content?.parts ?? [])
            .filter { $0.thought != true }
            .compactMap(\.text)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw GeminiError.emptyResponse }
        return text
    }

    // MARK: JSON de la API

    private struct RequestBody: Encodable {
        let systemInstruction: Content
        let contents: [Content]
    }

    private struct Content: Codable {
        let role: String?
        let parts: [Part]?
    }

    private struct Part: Codable {
        var text: String?
        var thought: Bool?
    }

    private struct ResponseBody: Decodable {
        struct Candidate: Decodable {
            let content: Content?
            let finishReason: String?
        }

        struct PromptFeedback: Decodable {
            let blockReason: String?
        }

        let candidates: [Candidate]?
        let promptFeedback: PromptFeedback?
    }

    private struct ErrorBody: Decodable {
        struct Detail: Decodable {
            let message: String
        }

        let error: Detail
    }
}
