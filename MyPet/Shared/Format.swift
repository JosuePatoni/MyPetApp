import Foundation

/// Textos de distancia, duración y calorías usados en paseos, recorridos y perfil.
enum Format {
    static func distance(_ meters: Double) -> String {
        Measurement(value: meters / 1000, unit: UnitLength.kilometers)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(2))))
    }

    static func duration(_ seconds: TimeInterval) -> String {
        Duration.seconds(max(seconds, 0)).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }

    /// Una línea por mascota: "Firulais: 12 kcal".
    static func calories(of pets: [Pet], walking meters: Double) -> String {
        pets.map { pet in
            if let kcal = Walk.calories(walking: meters, weight: pet.weight) {
                String(localized: "\(pet.name): \(Int(kcal.rounded())) kcal")
            } else {
                String(localized: "\(pet.name): registra su peso")
            }
        }
        .joined(separator: "\n")
    }
}
