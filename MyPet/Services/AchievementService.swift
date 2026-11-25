import Foundation
import SwiftData

@MainActor
struct AchievementService {
    let context: ModelContext

    /// Inserta los logros del catálogo que aún no existen en la base.
    func seedCatalog() {
        let existing = Set(((try? context.fetch(FetchDescriptor<Achievement>())) ?? []).map(\.code))
        for (index, code) in AchievementCode.allCases.enumerated() where !existing.contains(code.rawValue) {
            context.insert(Achievement(
                code: code.rawValue,
                name: code.name,
                details: code.details,
                experience: code.experience,
                order: index
            ))
        }
    }

    /// Desbloquea los logros que el usuario ya cumple (`AchievementCode.isMet`) y da su XP completa
    /// a cada mascota de `pets`: la que se agregó o editó, o las del paseo que lo provocó.
    /// No guarda; el llamador hace `save()`.
    func evaluate(for user: User, rewarding pets: [Pet]) {
        let owned = Set(user.achievements.map(\.code))
        let all = (try? context.fetch(FetchDescriptor<Achievement>(sortBy: [SortDescriptor(\.order)]))) ?? []
        for achievement in all where !owned.contains(achievement.code) {
            guard let code = AchievementCode(rawValue: achievement.code), code.isMet(by: user) else { continue }
            user.achievements.append(achievement)
            for pet in pets {
                pet.experience += achievement.experience
            }
        }
    }
}
