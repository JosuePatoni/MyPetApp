import Foundation
import SwiftData

/// Tabla `Mascota`. `Mascota_enfermedad` se resuelve como relación muchos-a-muchos con `Disease`.
@Model
final class Pet {
    static let experiencePerLevel = 50

    var name: String
    var species: Species
    var breed: String
    var birthDate: Date?
    /// Kilogramos.
    var weight: Double?
    /// JPEG reducido a 800 px como máximo; se guarda fuera de la base de datos.
    @Attribute(.externalStorage) var photoData: Data?
    var experience: Int = 0
    var owner: User?

    @Relationship(inverse: \Disease.pets)
    var diseases: [Disease] = []

    @Relationship(deleteRule: .cascade, inverse: \Walk.pet)
    var walks: [Walk] = []

    // ponytail: nivel calculado desde la experiencia, no guardado, para que nunca se desincronice
    /// Empieza en 1 y sube cada 50 XP.
    var level: Int { experience / Self.experiencePerLevel + 1 }

    init(
        name: String,
        species: Species,
        breed: String = "",
        birthDate: Date? = nil,
        weight: Double? = nil,
        photoData: Data? = nil
    ) {
        self.name = name
        self.species = species
        self.breed = breed
        self.birthDate = birthDate
        self.weight = weight
        self.photoData = photoData
    }
}
