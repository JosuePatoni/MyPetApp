import Foundation

/// Catálogo de recompensas. Para agregar una: nuevo `case` con su marca, textos, meta y plan.
/// `RewardService.evaluate` la entrega sola cuando el usuario cumple la meta.
enum RewardCode: String, CaseIterable {
    case huellas10km
    case michi5walks
    case lomitos25km
    case patitas10walks
    case bigotes7days
    case canela50km
    case huellas100km

    /// Vigencia del cupón desde que se desbloquea.
    static let validityMonths = 3

    var brand: BrandCode {
        switch self {
        case .huellas10km, .huellas100km: .huellas
        case .michi5walks: .michi
        case .lomitos25km: .lomitos
        case .patitas10walks: .patitas
        case .bigotes7days: .bigotes
        case .canela50km: .canela
        }
    }

    var title: String {
        switch self {
        case .huellas10km: String(localized: "20 % de descuento")
        case .michi5walks: String(localized: "15 % de descuento")
        case .lomitos25km: String(localized: "50 % de descuento")
        case .patitas10walks: String(localized: "2×1")
        case .bigotes7days: String(localized: "Envío gratis")
        case .canela50km: String(localized: "30 % de descuento")
        case .huellas100km: String(localized: "40 % de descuento")
        }
    }

    var details: String {
        switch self {
        case .huellas10km: String(localized: "En accesorios")
        case .michi5walks: String(localized: "En comida para gato")
        case .lomitos25km: String(localized: "En premios")
        case .patitas10walks: String(localized: "En baño y estética")
        case .bigotes7days: String(localized: "En tu siguiente pedido")
        case .canela50km: String(localized: "En consulta veterinaria")
        case .huellas100km: String(localized: "En toda la tienda")
        }
    }

    var requirement: RewardRequirement {
        switch self {
        case .huellas10km: .kilometers(10)
        case .michi5walks: .walks(5)
        case .lomitos25km: .kilometers(25)
        case .patitas10walks: .walks(10)
        case .bigotes7days: .activeDays(7)
        case .canela50km: .kilometers(50)
        case .huellas100km: .kilometers(100)
        }
    }

    var isPro: Bool {
        switch self {
        case .huellas10km, .michi5walks, .patitas10walks: false
        case .lomitos25km, .bigotes7days, .canela50km, .huellas100km: true
        }
    }

    /// Inicio del código de canje; se le agrega una parte aleatoria por usuario.
    var codePrefix: String {
        switch self {
        case .huellas10km: "HUELLAS20"
        case .michi5walks: "MICHI15"
        case .lomitos25km: "LOMITOS50"
        case .patitas10walks: "PATITAS2X1"
        case .bigotes7days: "BIGOTESENVIO"
        case .canela50km: "CANELA30"
        case .huellas100km: "HUELLAS40"
        }
    }
}
