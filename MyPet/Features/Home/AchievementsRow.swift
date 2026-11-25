import SwiftUI

/// Fila de medallas; al tocar una se abre su card.
struct AchievementsRow: View {
    let achievements: [Achievement]
    let unlockedCodes: Set<String>

    @State private var selected: Achievement?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(achievements) { achievement in
                    Button {
                        selected = achievement
                    } label: {
                        AchievementBadge(achievement: achievement, isUnlocked: unlockedCodes.contains(achievement.code))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollIndicators(.hidden)
        .sheet(item: $selected) { achievement in
            AchievementCard(achievement: achievement, isUnlocked: unlockedCodes.contains(achievement.code))
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}
