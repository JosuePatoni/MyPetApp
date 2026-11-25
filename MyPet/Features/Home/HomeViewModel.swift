import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    var selectedPetIndex = 0
    var isAddingPet = false

    func pets(of user: User) -> [Pet] {
        user.pets.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func unlockedCodes(of user: User) -> Set<String> {
        Set(user.achievements.map(\.code))
    }
}
