import Foundation

/// Catálogo de logros. Para agregar uno: nuevo `case` con su nombre, cómo se obtiene, XP y regla (`isMet`).
/// `AchievementService` lo precarga y lo entrega solo.
enum AchievementCode: String, CaseIterable {
    case firstFriend
    case fullFamily
    // Distancia acumulada
    case firstSteps
    case walker10km
    case explorer50km
    case marathoner100km
    // Paradas pet friendly
    case friendlyStop
    case petFriendlyNeighbor
    case cityGuide
    // Rendimiento de la mascota
    case longWalk
    case fastPace
    case fitPet

    var name: String {
        switch self {
        case .firstFriend: String(localized: "Mi primer amigo")
        case .fullFamily: String(localized: "Familia completa")
        case .firstSteps: String(localized: "Primeros pasos")
        case .walker10km: String(localized: "Caminante")
        case .explorer50km: String(localized: "Explorador")
        case .marathoner100km: String(localized: "Maratonista")
        case .friendlyStop: String(localized: "Parada amigable")
        case .petFriendlyNeighbor: String(localized: "Vecino pet friendly")
        case .cityGuide: String(localized: "Guía de la ciudad")
        case .longWalk: String(localized: "Paseo largo")
        case .fastPace: String(localized: "Paso veloz")
        case .fitPet: String(localized: "En forma")
        }
    }

    var details: String {
        switch self {
        case .firstFriend: String(localized: "Registra a tu primera mascota.")
        case .fullFamily: String(localized: "Ten un perro y un gato.")
        case .firstSteps: String(localized: "Camina 1 km en total.")
        case .walker10km: String(localized: "Camina 10 km en total.")
        case .explorer50km: String(localized: "Camina 50 km en total.")
        case .marathoner100km: String(localized: "Camina 100 km en total.")
        case .friendlyStop: String(localized: "Registra tu primera parada pet friendly durante un paseo.")
        case .petFriendlyNeighbor: String(localized: "Registra 10 paradas pet friendly.")
        case .cityGuide: String(localized: "Registra 25 paradas pet friendly.")
        case .longWalk: String(localized: "Haz un paseo de 5 km o más.")
        case .fastPace: String(localized: "Haz un paseo de al menos 1 km a 5 km/h o más.")
        case .fitPet: String(localized: "Lleva a una de tus mascotas al nivel 5.")
        }
    }

    var experience: Int {
        switch self {
        case .firstFriend: 50
        case .fullFamily: 100
        case .firstSteps: 20
        case .walker10km: 50
        case .explorer50km: 100
        case .marathoner100km: 200
        case .friendlyStop: 20
        case .petFriendlyNeighbor: 60
        case .cityGuide: 120
        case .longWalk: 60
        case .fastPace: 40
        case .fitPet: 80
        }
    }

    /// Regla del logro con los datos actuales del usuario.
    func isMet(by user: User) -> Bool {
        switch self {
        case .firstFriend:
            !user.pets.isEmpty
        case .fullFamily:
            Set(user.pets.map(\.species)).isSuperset(of: [.dog, .cat])
        case .firstSteps:
            user.walkedDistance >= 1_000
        case .walker10km:
            user.walkedDistance >= 10_000
        case .explorer50km:
            user.walkedDistance >= 50_000
        case .marathoner100km:
            user.walkedDistance >= 100_000
        case .friendlyStop:
            Self.stopCount(of: user) >= 1
        case .petFriendlyNeighbor:
            Self.stopCount(of: user) >= 10
        case .cityGuide:
            Self.stopCount(of: user) >= 25
        case .longWalk:
            user.walks.contains { $0.distance >= 5_000 }
        case .fastPace:
            // 5 km/h = 1.39 m/s, promedio de todo el paseo.
            user.walks.contains { $0.distance >= 1_000 && $0.duration > 0 && $0.distance / $0.duration >= 5_000 / 3_600 }
        case .fitPet:
            user.pets.contains { $0.level >= 5 }
        }
    }

    private static func stopCount(of user: User) -> Int {
        user.walks.reduce(0) { $0 + $1.petFriendlyStops.count }
    }
}
