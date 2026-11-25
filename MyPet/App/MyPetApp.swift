import SwiftData
import SwiftUI

@main
struct MyPetApp: App {
    @State private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
        }
        .modelContainer(for: [User.self, Pet.self, Walk.self, Route.self, Achievement.self, Disease.self, Reminder.self])
    }
}
