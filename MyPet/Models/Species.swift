import Foundation

/// Solo perros y gatos: los dos tienen recordatorio de paseo.
enum Species: String, Codable, CaseIterable, Identifiable {
    case dog
    case cat

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .dog: "Perro"
        case .cat: "Gato"
        }
    }

    var symbolName: String {
        switch self {
        case .dog: "dog.fill"
        case .cat: "cat.fill"
        }
    }

    /// "Mestizo" + las 15 razas más comunes en México. `Pet.breed` guarda el texto elegido.
    var breeds: [String] {
        switch self {
        case .dog:
            [
                "Mestizo", "Chihuahua", "Labrador Retriever", "Pastor Alemán", "Golden Retriever",
                "Bulldog Francés", "Schnauzer", "Poodle", "Yorkshire Terrier", "Pug", "Husky Siberiano",
                "Pitbull", "Shih Tzu", "Beagle", "Xoloitzcuintle", "Pomerania",
            ]
        case .cat:
            [
                "Mestizo", "Siamés", "Persa", "Angora Turco", "Maine Coon", "Bengalí", "Ragdoll",
                "Británico de pelo corto", "Azul Ruso", "Himalayo", "Sphynx", "Scottish Fold",
                "Exótico de pelo corto", "Abisinio", "Bombay", "Siberiano",
            ]
        }
    }
}
