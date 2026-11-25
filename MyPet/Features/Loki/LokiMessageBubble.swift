import SwiftUI

/// Burbuja de chat: Loki a la izquierda (con su carita de gato), el usuario a la derecha.
struct LokiMessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromLoki {
                Image(systemName: "cat.fill")
                    .font(.title3)
                    .foregroundStyle(MyPetPalette.teal)
                    .frame(width: 36, height: 36)
                    .background(MyPetPalette.apricot, in: .circle)
                    .accessibilityHidden(true)
            } else {
                Spacer(minLength: 48)
            }

            Text(formatted)
                .foregroundStyle(.black)
                .padding(12)
                .background(message.isFromLoki ? MyPetPalette.yellow : MyPetPalette.mint, in: .rect(cornerRadius: 16))
                .textSelection(.enabled)

            if message.isFromLoki {
                Spacer(minLength: 48)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message.isFromLoki ? Text("Loki dice: \(message.text)") : Text("Tú: \(message.text)"))
    }

    /// Negritas y cursivas de Markdown; las listas con guiones se ven tal cual, respetando los saltos de línea.
    private var formatted: AttributedString {
        (try? AttributedString(
            markdown: message.text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(message.text)
    }
}
