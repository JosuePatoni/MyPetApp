import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    var username = ""
    var password = ""
    var errorMessage: String?

    var canSubmit: Bool { !username.isEmpty && !password.isEmpty }

    func login(with auth: AuthService) -> User? {
        do {
            errorMessage = nil
            return try auth.login(username: username, password: password)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
