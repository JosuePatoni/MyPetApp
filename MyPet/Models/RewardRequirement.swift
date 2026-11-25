import Foundation

/// Meta para desbloquear una recompensa: distancia o uso de la app.
enum RewardRequirement {
    case kilometers(Double)
    /// Paseos terminados.
    case walks(Int)
    /// Días distintos con al menos un paseo.
    case activeDays(Int)

    var goal: Double {
        switch self {
        case .kilometers(let km): km
        case .walks(let count): Double(count)
        case .activeDays(let days): Double(days)
        }
    }

    /// Avance actual del usuario, en las mismas unidades que `goal`.
    @MainActor
    func progress(for user: User) -> Double {
        switch self {
        case .kilometers:
            user.walkedDistance / 1000
        case .walks:
            Double(user.walks.count)
        case .activeDays:
            Double(Set(user.walks.map { Calendar.current.startOfDay(for: $0.startDate) }).count)
        }
    }

    @MainActor
    func isMet(by user: User) -> Bool { progress(for: user) >= goal }

    var unlockText: String {
        switch self {
        case .kilometers(let km): String(localized: "Se desbloquea a los \(Int(km)) km")
        case .walks(let count): String(localized: "Se desbloquea al completar \(count) paseos")
        case .activeDays(let days): String(localized: "Se desbloquea al pasear \(days) días distintos")
        }
    }

    /// "42 / 100 km", "3 / 10 paseos", "2 / 7 días".
    func progressText(_ current: Double) -> String {
        switch self {
        case .kilometers(let km):
            String(localized: "\(min(current, km).formatted(.number.precision(.fractionLength(0...1)))) / \(Int(km)) km")
        case .walks(let count):
            String(localized: "\(min(Int(current), count)) / \(count) paseos")
        case .activeDays(let days):
            String(localized: "\(min(Int(current), days)) / \(days) días")
        }
    }
}
