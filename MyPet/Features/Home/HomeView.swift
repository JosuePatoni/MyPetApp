import SwiftData
import SwiftUI

struct HomeView: View {
    @Bindable var user: User

    @Environment(SessionStore.self) private var session
    @Query(sort: \Achievement.order) private var achievements: [Achievement]
    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack(path: $user.navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("¡Hola, \(user.username)!")
                            .font(.title.bold())
                        Text("¿Comenzamos con un paseo?")
                            .foregroundStyle(.secondary)
                    }

                    Text("Mis mascotas")
                        .font(.title2.bold())

                    PetCarousel(pets: viewModel.pets(of: user), selection: $viewModel.selectedPetIndex) {
                        viewModel.isAddingPet = true
                    }

                    HStack(spacing: 16) {
                        NavigationLink(value: HomeDestination.walks) {
                            HomeTile(title: "Mis paseos", systemImage: "figure.walk")
                        }
                        NavigationLink(value: HomeDestination.routes) {
                            HomeTile(title: "Recorridos", systemImage: "map")
                        }
                    }

                    NavigationLink(value: HomeDestination.reminders) {
                        HomeTile(title: "Mis recordatorios", systemImage: "alarm")
                    }

                    Text("Mis logros")
                        .font(.title2.bold())

                    AchievementsRow(achievements: achievements, unlockedCodes: viewModel.unlockedCodes(of: user))
                }
                .padding()
            }
            .navigationTitle("MyPet")
            .navigationDestination(for: HomeDestination.self) { destination in
                switch destination {
                case .reminders:
                    RemindersListView(user: user)
                case .pet(let id):
                    if let pet = viewModel.pet(withID: id, of: user) {
                        PetDetailView(pet: pet)
                    } else {
                        ContentUnavailableView("Mascota no encontrada", systemImage: "pawprint")
                    }
                case .petReminder(let id):
                    if let pet = viewModel.pet(withID: id, of: user) {
                        ReminderSettingsView(pet: pet)
                    } else {
                        ContentUnavailableView("Mascota no encontrada", systemImage: "pawprint")
                    }
                case .walks, .routes:
                    ComingSoonView(title: destination.title)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Agregar mascota", systemImage: "plus") {
                        viewModel.isAddingPet = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("Perfil", systemImage: "person.crop.circle") {
                        Section(user.username) {
                            Button("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive, action: session.signOut)
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.isAddingPet) {
                AddPetView(owner: user)
            }
        }
    }
}
