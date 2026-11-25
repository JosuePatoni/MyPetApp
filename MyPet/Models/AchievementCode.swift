import Foundation

/// Catálogo de logros. Para agregar uno: nuevo `case` + su regla en `AchievementService.evaluate`.
enum AchievementCode: String, CaseIterable {
    case firstFriend
    case fullFamily

    var name: String {
        switch self {
        case .firstFriend: String(localized: "Mi primer amigo")
        case .fullFamily: String(localized: "Familia completa")
        }
    }

    var details: String {
        switch self {
        case .firstFriend: String(localized: "Registra a tu primera mascota.")
        case .fullFamily: String(localized: "Ten un perro y un gato.")
        }
    }

    var experience: Int {
        switch self {
        case .firstFriend: 50
        case .fullFamily: 100
        }
    }
}
