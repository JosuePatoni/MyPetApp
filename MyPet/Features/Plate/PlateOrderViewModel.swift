import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class PlateOrderViewModel {
    static let price: Decimal = 100
    static let maxEngravingLength = 40

    var shape = PlateShape.circle
    var color = PlateColor.silver
    var engraving: String
    private(set) var isPaying = false
    var isConfirmed = false
    var errorMessage: String?

    init(pet: Pet, owner: User) {
        engraving = owner.phone.isEmpty ? pet.name : "\(pet.name)\n\(owner.phone)"
    }

    func canPay(owner: User) -> Bool {
        let text = engraving.trimmingCharacters(in: .whitespacesAndNewlines)
        return !isPaying
            && !text.isEmpty
            && text.count <= Self.maxEngravingLength
            && !owner.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func pay(for pet: Pet, in context: ModelContext) async {
        isPaying = true
        defer { isPaying = false }
        // ponytail: pago simulado, no cobra nada. Uno real necesita backend + pasarela (Stripe, Mercado Pago).
        try? await Task.sleep(for: .seconds(2))
        pet.plateOrderDate = .now
        do {
            try context.save()
            isConfirmed = true
        } catch {
            context.rollback()
            errorMessage = error.localizedDescription
        }
    }
}
