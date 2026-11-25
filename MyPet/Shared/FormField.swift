import SwiftUI

/// Etiqueta encima del campo, como en el boceto.
struct FormField<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .accessibilityHidden(true)
            content
                .textFieldStyle(.roundedBorder)
        }
    }
}
