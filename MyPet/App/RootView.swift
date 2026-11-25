import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if let user = session.currentUser {
                if user.hasCompletedSetup {
                    HomeView(user: user)
                } else {
                    SetupView(user: user)
                }
            } else {
                LoginView()
            }
        }
        .task {
            AchievementService(context: modelContext).seedCatalog()
            RewardService(context: modelContext).seedBrands()
            DemoWalkerSeeder(context: modelContext).seed()
            session.restore(using: AuthService(context: modelContext))
            await ReminderScheduler.rescheduleAll(in: modelContext)
        }
    }
}
