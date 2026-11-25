import Foundation
import Observation

@MainActor
@Observable
final class RegisterViewModel {
    var username = ""
    var email = ""
    var password = ""
    var confirmPassword = ""
    var errorMessage: String?

    var canSubmit: Bool {
        !username.isEmpty && !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty
    }

    func register(with auth: AuthService) -> User? {
        do {
            errorMessage = nil
            guard password == confirmPassword else { throw AuthError.passwordMismatch }
            return try auth.register(username: username, email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
