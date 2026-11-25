import SwiftUI

struct AchievementsRow: View {
    let achievements: [Achievement]
    let unlockedCodes: Set<String>

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(achievements) { achievement in
                    AchievementBadge(achievement: achievement, isUnlocked: unlockedCodes.contains(achievement.code))
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}
