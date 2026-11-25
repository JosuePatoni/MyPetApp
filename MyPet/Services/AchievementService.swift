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

    /// Desbloquea los logros que el usuario ya cumple y da su XP a `pet`, la mascota que lo provocó.
    /// No guarda; el llamador hace `save()`.
    func evaluate(for user: User, rewarding pet: Pet) {
        let species = Set(user.pets.map(\.species))
        var earned: Set<String> = []
        if !user.pets.isEmpty { earned.insert(AchievementCode.firstFriend.rawValue) }
        if species.isSuperset(of: [.dog, .cat]) { earned.insert(AchievementCode.fullFamily.rawValue) }

        let owned = Set(user.achievements.map(\.code))
        let all = (try? context.fetch(FetchDescriptor<Achievement>())) ?? []
        for achievement in all where earned.contains(achievement.code) && !owned.contains(achievement.code) {
            user.achievements.append(achievement)
            pet.experience += achievement.experience
        }
    }
}
