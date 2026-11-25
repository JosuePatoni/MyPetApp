import SwiftUI

/// Card de un logro: título, cómo se obtiene, XP y si ya está conseguido.
struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "medal.fill")
                .font(.system(size: 72))
                .foregroundStyle(isUnlocked ? Color.orange : Color.gray)
                .accessibilityHidden(true)

            Text(achievement.name)
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Label(
                isUnlocked ? "Conseguido" : "No conseguido",
                systemImage: isUnlocked ? "checkmark.seal.fill" : "lock.fill"
            )
            .font(.subheadline.bold())
            .foregroundStyle(isUnlocked ? Color.green : Color.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Cómo se obtiene")
                    .font(.headline)
                Text(achievement.details)
                Text("+\(achievement.experience) XP para la mascota que lo desbloquea.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.fill.tertiary, in: .rect(cornerRadius: 16))
        }
        .padding(24)
    }
}
