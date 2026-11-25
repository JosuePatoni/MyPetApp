import SwiftUI

/// Perfil del paseador: calificación, XP, paseos y comentarios que le dejaron los dueños.
struct WalkerStatsView: View {
    let walker: User

    /// Paseos calificados, del más reciente al más antiguo.
    private var reviews: [Walk] {
        walker.walksAsWalker
            .filter { $0.rating != nil }
            .sorted { $0.startDate > $1.startDate }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Calificación")
                    .font(.title3.bold())
                StarRatingLabel(average: walker.averageRating, count: walker.ratingCount)
                    .font(.title3)
                HStack {
                    PetStat(value: Text("\(walker.walkerExperience) XP"), label: "Experiencia")
                    PetStat(value: Text("\(walker.walkerWalkCount)"), label: "Paseos")
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.black)
            .background(MyPetPalette.mint, in: .rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(MyPetPalette.teal, lineWidth: 1.5)
            }

            Text("Comentarios de los dueños")
                .font(.title3.bold())
            if reviews.isEmpty {
                Text("Aún no tienes comentarios.")
                    .foregroundStyle(.secondary)
            }
            ForEach(reviews) { walk in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        StarRatingLabel(average: Double(walk.rating ?? 0))
                            .font(.caption)
                        Spacer()
                        Text(walk.startDate, format: .dateTime.day().month().year())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if !walk.comment.isEmpty {
                        Text(walk.comment)
                    }
                    Text("\(walk.user?.username ?? String(localized: "Dueño")) · \(walk.pets.map(\.name).formatted(.list(type: .and)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MyPetPalette.yellow.opacity(0.5), in: .rect(cornerRadius: 14))
                .accessibilityElement(children: .combine)
            }
        }
    }
}
