import SwiftUI
import UIKit

/// Cupón abierto (wireframe 16): descuento, código de canje único y dónde usarlo.
struct CouponDetailView: View {
    let reward: Reward

    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    private var brandName: String { reward.brand?.name ?? String(localized: "Marca") }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    Image(systemName: reward.brand?.symbolName ?? "ticket.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(MyPetPalette.teal)
                        .accessibilityHidden(true)

                    Text(reward.title)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text(reward.details)
                        .font(.title3)

                    Text("Código de canje")
                        .font(.headline)
                        .padding(.top, 8)
                    Text(reward.code)
                        .font(.title2.monospaced().bold())
                        .kerning(2)
                        .textSelection(.enabled)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(MyPetPalette.mint, in: .rect(cornerRadius: 14))

                    Button(copied ? "Copiado" : "Copiar código", systemImage: copied ? "checkmark" : "doc.on.doc") {
                        UIPasteboard.general.string = reward.code
                        copied = true
                    }
                    .buttonStyle(.bordered)
                    .tint(MyPetPalette.teal)

                    Text("Úsalo en línea o muéstralo en tienda.")
                        .multilineTextAlignment(.center)
                    Text(reward.isExpired
                         ? "Venció el \(reward.expiresAt.formatted(date: .numeric, time: .omitted))"
                         : "Válido hasta el \(reward.expiresAt.formatted(date: .numeric, time: .omitted))")
                        .foregroundStyle(reward.isExpired ? .red : .secondary)

                    if let brand = reward.brand {
                        if let url = URL(string: brand.website), !brand.website.isEmpty {
                            Link("Ir a la tienda en línea de \(brand.name)", destination: url)
                        }
                        if !brand.phone.isEmpty, let tel = URL(string: "tel:\(brand.phone.filter(\.isNumber))") {
                            Link("Llamar a \(brand.name)", destination: tel)
                        }
                    }
                }
                .padding(24)
            }
            .navigationTitle("Cupón de \(brandName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar", systemImage: "xmark.circle") { dismiss() }
                }
            }
        }
    }
}
