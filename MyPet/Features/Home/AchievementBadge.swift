import SwiftUI

/// Medalla de logro: a color si está conseguido, gris si no.
struct AchievementBadge: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Image(systemName: "medal.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(isUnlocked ? MyPetPalette.turquoise : Color.secondary)
                Image(systemName: isUnlocked ? "star.fill" : "lock.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.black)
                    .padding(5)
                    .background(isUnlocked ? MyPetPalette.yellow : MyPetPalette.mint, in: .circle)
            }
            .accessibilityHidden(true)
            Text(achievement.name)
                .font(.caption)
                .multilineTextAlignment(.center)
            Text("+\(achievement.experience) XP")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 90)
        .accessibilityElement(children: .combine)
        .accessibilityValue(isUnlocked ? Text("Conseguido") : Text("No conseguido"))
        .accessibilityHint("Muestra cómo se obtiene")
    }
}
