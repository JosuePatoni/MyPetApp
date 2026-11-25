import Foundation
import SwiftData

/// Registro e inicio de sesión locales contra SwiftData.
/// ponytail: struct concreto; extraer un protocolo cuando exista un backend.
@MainActor
struct AuthService {
    let context: ModelContext

    func register(username: String, email: String, password: String) throws -> User {
        let username = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !username.isEmpty else { throw AuthError.emptyUsername }
        guard email.wholeMatch(of: /[^@\s]+@[^@\s]+\.[^@\s]+/) != nil else { throw AuthError.invalidEmail }
        guard password.count >= 8 else { throw AuthError.weakPassword }
        guard user(named: username) == nil else { throw AuthError.usernameTaken }

        let salt = PasswordHasher.makeSalt()
        let user = User(
            username: username,
            email: email,
            passwordHash: PasswordHasher.hash(password, salt: salt),
            passwordSalt: salt
        )
        context.insert(user)
        try context.save()
        return user
    }

    func login(username: String, password: String) throws -> User {
        let username = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let user = user(named: username),
              PasswordHasher.hash(password, salt: user.passwordSalt) == user.passwordHash
        else { throw AuthError.invalidCredentials }
        return user
    }

    func user(named username: String) -> User? {
        var descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.username == username })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
