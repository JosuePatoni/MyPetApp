import CommonCrypto
import Foundation

enum PasswordHasher {
    // ponytail: PBKDF2 en el hilo principal (~100 ms); mover a Task si se nota en login
    private static let rounds: UInt32 = 100_000

    static func makeSalt() -> Data {
        // SystemRandomNumberGenerator es criptográficamente seguro en plataformas Apple.
        Data((0..<16).map { _ in UInt8.random(in: .min ... .max) })
    }

    static func hash(_ password: String, salt: Data) -> Data {
        var derived = [UInt8](repeating: 0, count: 32)
        let saltBytes = [UInt8](salt)
        let status = CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            password, password.utf8.count,
            saltBytes, saltBytes.count,
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
            rounds,
            &derived, derived.count
        )
        precondition(status == Int32(kCCSuccess), "PBKDF2 failed: \(status)")
        return Data(derived)
    }
}
