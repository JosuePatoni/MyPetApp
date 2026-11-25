import Foundation

/// Catálogo de marcas aliadas (ficticias, de los wireframes).
// ponytail: catálogo fijo en la app; cuando haya convenios reales, descargarlo de un backend
enum BrandCode: String, CaseIterable {
    case huellas
    case lomitos
    case michi
    case patitas
    case canela
    case bigotes

    var name: String {
        switch self {
        case .huellas: "Huellas"
        case .lomitos: "Lomitos"
        case .michi: "Michi"
        case .patitas: "Patitas"
        case .canela: "Canela"
        case .bigotes: "Bigotes"
        }
    }

    var symbolName: String {
        switch self {
        case .huellas: "pawprint.fill"
        case .lomitos: "gift.fill"
        case .michi: "cat.fill"
        case .patitas: "bubbles.and.sparkles.fill"
        case .canela: "cross.case.fill"
        case .bigotes: "shippingbox.fill"
        }
    }

    /// Dominio reservado para ejemplos: reemplazar por el sitio real de cada marca.
    var website: String { "https://\(rawValue).example.com" }

    /// Vacío hasta tener el teléfono real de la marca.
    var phone: String { "" }
}
