import Foundation

enum AuthError: LocalizedError {
    case emptyUsername
    case invalidEmail
    case weakPassword
    case passwordMismatch
    case usernameTaken
    case invalidCredentials
    case wrongCurrentPassword

    var errorDescription: String? {
        switch self {
        case .emptyUsername: String(localized: "Escribe un nombre de usuario.")
        case .invalidEmail: String(localized: "El correo electrónico no es válido.")
        case .weakPassword: String(localized: "La contraseña debe tener al menos 8 caracteres.")
        case .passwordMismatch: String(localized: "Las contraseñas no coinciden.")
        case .usernameTaken: String(localized: "Ese nombre de usuario ya existe.")
        case .invalidCredentials: String(localized: "Usuario o contraseña incorrectos.")
        case .wrongCurrentPassword: String(localized: "La contraseña actual no es correcta.")
        }
    }
}
