import Foundation
import SwiftData

@MainActor
struct RewardService {
    let context: ModelContext

    /// Inserta las marcas del catálogo que aún no existen en la base.
    func seedBrands() {
        let existing = Set(((try? context.fetch(FetchDescriptor<Brand>())) ?? []).map(\.code))
        for (index, brand) in BrandCode.allCases.enumerated() where !existing.contains(brand.rawValue) {
            context.insert(Brand(
                code: brand.rawValue,
                name: brand.name,
                symbolName: brand.symbolName,
                website: brand.website,
                phone: brand.phone,
                order: index
            ))
        }
    }

    /// Entrega los cupones cuya meta ya se cumplió y que el usuario aún no tiene.
    /// Los cupones Pro también se entregan con plan Básico, pero quedan bloqueados hasta pasar a Pro.
    /// No guarda; el llamador hace `save()`.
    func evaluate(for user: User) {
        let owned = Set(user.rewards.map(\.catalogCode))
        let brands = Dictionary(
            ((try? context.fetch(FetchDescriptor<Brand>())) ?? []).map { ($0.code, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let now = Date.now
        let expiresAt = Calendar.current.date(byAdding: .month, value: RewardCode.validityMonths, to: now)
            ?? now.addingTimeInterval(90 * 86_400)

        for reward in RewardCode.allCases where !owned.contains(reward.rawValue) && reward.requirement.isMet(by: user) {
            let coupon = Reward(
                catalogCode: reward.rawValue,
                code: Self.makeCode(prefix: reward.codePrefix),
                title: reward.title,
                details: reward.details,
                isPro: reward.isPro,
                unlockedAt: now,
                expiresAt: expiresAt
            )
            context.insert(coupon)
            coupon.user = user
            coupon.brand = brands[reward.brand.rawValue]
        }
    }

    /// La recompensa pendiente más cercana a desbloquearse (mayor avance), o `nil` si ya tiene todas.
    func nextReward(for user: User) -> (code: RewardCode, progress: Double)? {
        let owned = Set(user.rewards.map(\.catalogCode))
        return RewardCode.allCases
            .filter { !owned.contains($0.rawValue) }
            .map { (code: $0, progress: $0.requirement.progress(for: user)) }
            .max { $0.progress / $0.code.requirement.goal < $1.progress / $1.code.requirement.goal }
    }

    /// "HUELLAS20-7K3QX9": prefijo de la marca + 6 caracteres aleatorios sin 0/O ni 1/I para dictarlo sin errores.
    // ponytail: único en la práctica (32^6 ≈ 10^9), pero la marca no puede validarlo sin un servidor compartido
    static func makeCode(prefix: String) -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        let suffix = (0..<6).map { _ in alphabet.randomElement() ?? "X" }
        return "\(prefix)-\(String(suffix))"
    }
}
