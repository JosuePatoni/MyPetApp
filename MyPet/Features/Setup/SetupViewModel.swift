import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class SetupViewModel {
    var role = UserRole.owner
    var errorMessage: String?

    func finish(user: User, in context: ModelContext) {
        user.role = role
        user.hasCompletedSetup = true
        do {
            try context.save()
        } catch {
            context.rollback()
            errorMessage = error.localizedDescription
        }
    }
}
