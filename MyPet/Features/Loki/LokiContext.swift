import Foundation

/// JSON con lo mínimo que Loki necesita. Sin dirección, teléfono, correo ni coordenadas GPS: se envía a Google.
struct LokiContext: Encodable {
    struct UserInfo: Encodable {
        let nombre: String
        let rol: String
        let kmCaminados: Double
    }

    struct PetInfo: Encodable {
        let nombre: String
        let especie: String
        let raza: String
        let edad: String?
        let pesoKg: Double?
        let nivel: Int
        let experiencia: Int
        let recordatorioPaseos: ReminderInfo?
        let paseosRecientes: [WalkInfo]
    }

    struct ReminderInfo: Encodable {
        let activo: Bool
        let cadaDias: Int
        let horas: [String]
    }

    struct WalkInfo: Encodable {
        let fecha: String
        let distanciaKm: Double
        let duracionMin: Int
        let caloriasKcal: Int?
        let paradasPetFriendly: Int
    }

    let fechaHoy: String
    let usuario: UserInfo
    let mascota: PetInfo

    /// Cuántos paseos recientes se mandan (los más nuevos primero).
    static let recentWalkLimit = 10

    init(user: User, pet: Pet, now: Date = .now) {
        let day = Date.ISO8601FormatStyle(timeZone: .current).year().month().day()
        fechaHoy = now.formatted(day)
        usuario = UserInfo(
            nombre: user.username,
            rol: String(localized: user.role.title),
            kmCaminados: Self.round(user.walkedDistance / 1000)
        )
        let walks = pet.walks
            .sorted { $0.startDate > $1.startDate }
            .prefix(Self.recentWalkLimit)
            .map { walk in
                WalkInfo(
                    fecha: walk.startDate.formatted(day),
                    distanciaKm: Self.round(walk.distance / 1000),
                    duracionMin: Int((walk.duration / 60).rounded()),
                    caloriasKcal: Walk.calories(walking: walk.distance, weight: pet.weight).map { Int($0.rounded()) },
                    paradasPetFriendly: walk.petFriendlyStops.count
                )
            }
        mascota = PetInfo(
            nombre: pet.name,
            especie: String(localized: pet.species.title),
            raza: pet.breed,
            edad: pet.birthDate.map { Self.age(from: $0, to: now) },
            pesoKg: pet.weight,
            nivel: pet.level,
            experiencia: pet.experience,
            recordatorioPaseos: pet.reminder.map { reminder in
                ReminderInfo(
                    activo: reminder.isEnabled,
                    cadaDias: reminder.everyDays,
                    horas: reminder.times.map { String(format: "%02d:%02d", $0 / 60, $0 % 60) }
                )
            },
            paseosRecientes: Array(walks)
        )
    }

    func json() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(self) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }

    /// "3 años y 2 meses" / "5 meses".
    private static func age(from birth: Date, to now: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month], from: birth, to: now)
        let years = parts.year ?? 0
        let months = parts.month ?? 0
        if years == 0 { return String(localized: "\(months) meses") }
        return String(localized: "\(years) años y \(months) meses")
    }

    private static func round(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}
