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
    var breed = Species.dog.breeds[0]
    var birthDate = Date.now
    var weight: Double?
    var photoItem: PhotosPickerItem?
    private(set) var photoData: Data?
    var reminder = ReminderDraft()
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
            breed: breed,
            birthDate: birthDate,
            weight: weight,
            photoData: photoData
        )
        context.insert(pet)
        owner.pets.append(pet)
        if species.canBeWalked {
            let newReminder = Reminder()
            context.insert(newReminder)
            reminder.apply(to: newReminder)
            pet.reminder = newReminder
        }
        AchievementService(context: context).evaluate(for: owner, rewarding: pet)

        do {
            try context.save()
            if let reminder = pet.reminder {
                Task { await ReminderScheduler.schedule(reminder) }
            }
            return true
        } catch {
            context.rollback()
            errorMessage = error.localizedDescription
            return false
        }
    }
}
