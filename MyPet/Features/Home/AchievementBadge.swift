import SwiftUI

/// Medalla de logro: a color si está conseguido, gris si no.
struct AchievementBadge: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "medal.fill")
                .font(.largeTitle)
                .foregroundStyle(isUnlocked ? Color.orange : Color.gray)
            Text(achievement.name)
                .font(.caption)
                .multilineTextAlignment(.center)
            Text("+\(achievement.experience) XP")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 90)
        .opacity(isUnlocked ? 1 : 0.5)
        .accessibilityElement(children: .combine)
        .accessibilityValue(isUnlocked ? Text("Conseguido") : Text("No conseguido"))
        .accessibilityHint(achievement.details)
    }
}
