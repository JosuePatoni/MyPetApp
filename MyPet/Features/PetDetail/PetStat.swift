import SwiftUI

/// Dato de la card: valor grande arriba y etiqueta pequeña abajo.
struct PetStat: View {
    let value: Text
    let label: LocalizedStringResource

    var body: some View {
        VStack(spacing: 4) {
            value
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
