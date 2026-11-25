import SwiftUI

/// Card de cupón: ícono de la marca | marca, descuento, categoría y vigencia. Bloqueada si es Pro y el plan es Básico.
struct RewardCouponCard: View {
    let reward: Reward
    let isLocked: Bool
    let fill: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: reward.brand?.symbolName ?? "ticket.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(MyPetPalette.teal)
                    .frame(width: 64)
                    .accessibilityHidden(true)

                Rectangle()
                    .fill(MyPetPalette.teal)
                    .frame(width: 1.5)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(reward.brand?.name ?? String(localized: "Marca"))
                        .font(.title3.bold())
                    Text(reward.title)
                        .font(.headline)
                    Text(reward.details)
                        .font(.subheadline)
                    Text(validityText)
                        .font(.subheadline)
                }

                Spacer(minLength: 0)

                if isLocked {
                    Image(systemName: "lock")
                        .accessibilityHidden(true)
                    Text("Pro")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(MyPetPalette.yellow, in: .capsule)
                        .overlay { Capsule().strokeBorder(MyPetPalette.teal, lineWidth: 1) }
                } else {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(.black)
            .padding()
            .fixedSize(horizontal: false, vertical: true)
            .background(isLocked ? MyPetPalette.yellow.opacity(0.35) : fill, in: .rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(isLocked ? .gray : MyPetPalette.teal, lineWidth: 1.5)
            }
            .opacity(isLocked || reward.isExpired ? 0.7 : 1)
            .contentShape(.rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(isLocked ? "Disponible con el plan Pro" : "Muestra el código de canje")
    }

    private var validityText: String {
        let date = reward.expiresAt.formatted(date: .numeric, time: .omitted)
        return reward.isExpired
            ? String(localized: "Venció el \(date)")
            : String(localized: "Válido hasta el \(date)")
    }
}
