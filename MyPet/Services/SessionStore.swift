import Foundation
import Observation

/// Usuario con sesión activa. El nombre de usuario se guarda en Keychain para mantener la sesión.
@MainActor
@Observable
final class SessionStore {
    private static let keychainKey = "currentUsername"

    private(set) var currentUser: User?

    func signIn(_ user: User) {
        currentUser = user
        Keychain.save(user.username, for: Self.keychainKey)
    }

    func signOut() {
        currentUser = nil
        Keychain.delete(Self.keychainKey)
    }

    func restore(using auth: AuthService) {
        guard currentUser == nil, let username = Keychain.read(Self.keychainKey) else { return }
        currentUser = auth.user(named: username)
    }
}
