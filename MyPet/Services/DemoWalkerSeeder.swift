import Foundation
import SwiftData

/// Precarga paseadores de ejemplo para que el dueño tenga a quién elegir sin crear cuentas.
// ponytail: datos ficticios locales; quitar cuando la lista venga de un servidor
@MainActor
struct DemoWalkerSeeder {
    let context: ModelContext

    private static let walkers: [(username: String, experience: Int, walks: Int, ratingSum: Int, ratingCount: Int)] = [
        ("Ana Martínez", 1_240, 48, 96, 20),
        ("Luis Hernández", 640, 25, 42, 10),
        ("Sofía Ramírez", 2_350, 90, 147, 30),
        ("Diego Torres", 300, 12, 20, 5),
    ]

    func seed() {
        let auth = AuthService(context: context)
        for demo in Self.walkers where auth.user(named: demo.username) == nil {
            // Hash de bytes aleatorios: ninguna contraseña coincide, así que nadie puede entrar con esta cuenta.
            let walker = User(
                username: demo.username,
                email: "",
                passwordHash: PasswordHasher.makeSalt() + PasswordHasher.makeSalt(),
                passwordSalt: PasswordHasher.makeSalt()
            )
            walker.role = .walker
            walker.hasCompletedSetup = true
            walker.isDemo = true
            walker.walkerExperience = demo.experience
            walker.walkerWalkCount = demo.walks
            walker.ratingSum = demo.ratingSum
            walker.ratingCount = demo.ratingCount
            context.insert(walker)
        }
    }
}
