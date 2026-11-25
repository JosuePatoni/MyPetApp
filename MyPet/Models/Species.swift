import Foundation

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
}
