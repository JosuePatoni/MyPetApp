import Foundation

enum Species: String, Codable, CaseIterable, Identifiable {
    case dog
    case cat
    case bird
    case turtle

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .dog: "Perro"
        case .cat: "Gato"
        case .bird: "Ave"
        case .turtle: "Tortuga"
        }
    }

    var symbolName: String {
        switch self {
        case .dog: "dog.fill"
        case .cat: "cat.fill"
        case .bird: "bird.fill"
        case .turtle: "tortoise.fill"
        }
    }

    /// Solo perros y gatos tienen recordatorio de paseo.
    var canBeWalked: Bool {
        switch self {
        case .dog, .cat: true
        case .bird, .turtle: false
        }
    }

    /// Las aves y tortugas se clasifican por especie, no por raza.
    var breedTitle: LocalizedStringResource {
        switch self {
        case .dog, .cat: "Raza"
        case .bird, .turtle: "Especie"
        }
    }

    /// Catálogo de razas/especies más comunes. `Pet.breed` guarda el texto elegido.
    var breeds: [String] {
        switch self {
        case .dog:
            ["Labrador Retriever", "Chihuahua", "Pastor Alemán", "Golden Retriever", "Bulldog Francés"]
        case .cat:
            ["Persa", "Siamés", "Maine Coon", "Británico de pelo corto", "Ragdoll"]
        case .bird:
            ["Periquito australiano", "Canario", "Ninfa (cacatúa)"]
        case .turtle:
            ["Tortuga de orejas rojas", "Tortuga rusa", "Tortuga mediterránea"]
        }
    }
}
