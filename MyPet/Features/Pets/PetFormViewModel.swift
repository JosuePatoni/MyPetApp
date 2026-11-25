import Foundation
import Observation
import PhotosUI
import SwiftData
import SwiftUI

/// Formulario para crear una mascota o, si recibe `pet`, editarla.
@MainActor
@Observable
final class PetFormViewModel {
    let pet: Pet?
    var name = ""
    var species = Species.dog
    var breed = Species.dog.breeds[0]
    var birthDate = Date.now
    var weight: Double?
    var photoItem: PhotosPickerItem?
    private(set) var photoData: Data?
    /// Solo al crear; al editar, el recordatorio tiene su propia pantalla.
    var reminder = ReminderDraft()
    var errorMessage: String?

    init(pet: Pet? = nil) {
        self.pet = pet
        guard let pet else { return }
        name = pet.name
        species = pet.species
        breed = pet.breed
        birthDate = pet.birthDate ?? .now
        weight = pet.weight
        photoData = pet.photoData
    }

    var isEditing: Bool { pet != nil }

    var canSave: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    func loadPhoto() async {
        guard let photoItem,
              let data = try? await photoItem.loadTransferable(type: Data.self)
        else { return }
        photoData = ImageDownscaler.jpegData(from: data)
    }

    func save(owner: User, in context: ModelContext) -> Bool {
        let target: Pet
        if let pet {
            target = pet
        } else {
            target = Pet(name: "", species: species)
            context.insert(target)
            owner.pets.append(target)
            let newReminder = Reminder()
            context.insert(newReminder)
            reminder.apply(to: newReminder)
            target.reminder = newReminder
        }
        target.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        target.species = species
        target.breed = breed
        target.birthDate = birthDate
        target.weight = weight
        target.photoData = photoData
        // Al editar puede cambiar la especie (p. ej. completar "Familia completa").
        AchievementService(context: context).evaluate(for: owner, rewarding: [target])

        do {
            try context.save()
            // Se reprograma también al editar: la notificación lleva el nombre de la mascota.
            if let reminder = target.reminder {
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
