import SwiftData
import SwiftUI

/// "Recompensas": todos los logros con cómo se obtienen y si ya están conseguidos.
struct RewardsView: View {
    let user: User

    @Query(sort: \Achievement.order) private var achievements: [Achievement]

    var body: some View {
        let unlocked = Set(user.achievements.map(\.code))
        ScrollView {
            VStack(spacing: 16) {
                ForEach(achievements) { achievement in
                    AchievementCard(achievement: achievement, isUnlocked: unlocked.contains(achievement.code))
                        .background(.fill.quaternary, in: .rect(cornerRadius: 24))
                }
            }
            .padding()
        }
        .navigationTitle("Recompensas")
    }
}
