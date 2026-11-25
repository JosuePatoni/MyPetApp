import Foundation
import Observation
import PhotosUI
import SwiftData
import SwiftUI

@MainActor
@Observable
final class AddPetViewModel {
    var name = ""
    var species = Species.dog
    var breed = ""
    var birthDate = Date.now
    var weight: Double?
    var photoItem: PhotosPickerItem?
    private(set) var photoData: Data?
    var errorMessage: String?

    var canSave: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    func loadPhoto() async {
        guard let photoItem,
              let data = try? await photoItem.loadTransferable(type: Data.self)
        else { return }
        photoData = ImageDownscaler.jpegData(from: data)
    }

    func save(owner: User, in context: ModelContext) -> Bool {
        let pet = Pet(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            species: species,
            breed: breed.trimmingCharacters(in: .whitespacesAndNewlines),
            birthDate: birthDate,
            weight: weight,
            photoData: photoData
        )
        context.insert(pet)
        owner.pets.append(pet)
        AchievementService(context: context).evaluate(for: owner, rewarding: pet)

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
