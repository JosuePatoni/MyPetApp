import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class ProPlanViewModel {
    static let monthlyPrice: Decimal = 49

    private(set) var isPaying = false
    var errorMessage: String?

    func subscribe(_ user: User, in context: ModelContext) async -> Bool {
        isPaying = true
        defer { isPaying = false }
        // ponytail: pago simulado, no cobra ni renueva. Uno real: StoreKit 2 con suscripción auto-renovable.
        try? await Task.sleep(for: .seconds(2))
        return setPro(true, for: user, in: context)
    }

    func cancel(_ user: User, in context: ModelContext) -> Bool {
        setPro(false, for: user, in: context)
    }

    private func setPro(_ isPro: Bool, for user: User, in context: ModelContext) -> Bool {
        user.isPro = isPro
        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            errorMessage = error.localizedDescription
            return false
        }
    }
}
