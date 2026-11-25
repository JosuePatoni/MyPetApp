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

    /// Cambia nombre, foto y, si `newPassword` o `confirmPassword` no están vacías, la contraseña
    /// (pide la actual). Valida todo antes de modificar al usuario.
    func updateProfile(
        _ user: User,
        username: String,
        photoData: Data?,
        currentPassword: String,
        newPassword: String,
        confirmPassword: String
    ) throws {
        let username = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !username.isEmpty else { throw AuthError.emptyUsername }
        if username != user.username, self.user(named: username) != nil { throw AuthError.usernameTaken }

        let changesPassword = !newPassword.isEmpty || !confirmPassword.isEmpty
        if changesPassword {
            guard PasswordHasher.hash(currentPassword, salt: user.passwordSalt) == user.passwordHash else {
                throw AuthError.wrongCurrentPassword
            }
            guard newPassword.count >= 8 else { throw AuthError.weakPassword }
            guard newPassword == confirmPassword else { throw AuthError.passwordMismatch }
        }

        user.username = username
        user.photoData = photoData
        if changesPassword {
            let salt = PasswordHasher.makeSalt()
            user.passwordSalt = salt
            user.passwordHash = PasswordHasher.hash(newPassword, salt: salt)
        }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func user(named username: String) -> User? {
        var descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.username == username })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
