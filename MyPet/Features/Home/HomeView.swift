import SwiftData
import SwiftUI

struct HomeView: View {
    @Bindable var user: User

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
                            HomeTile(title: "Mis recorridos", systemImage: "map")
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
                case .pet(let id), .petReminder(let id), .petQR(let id), .petPlate(let id):
                    // Se busca por UUID en cada render: si la mascota se eliminó, no se lee el objeto borrado.
                    if let pet = viewModel.pet(withID: id, of: user) {
                        switch destination {
                        case .petReminder: ReminderSettingsView(pet: pet)
                        case .petQR: PetQRView(pet: pet, owner: user)
                        case .petPlate: PlateOrderView(pet: pet, owner: user)
                        default: PetDetailView(pet: pet, owner: user)
                        }
                    } else {
                        ContentUnavailableView("Mascota no encontrada", systemImage: "pawprint")
                    }
                case .walks:
                    WalksListView(user: user)
                case .newWalk:
                    NewWalkView(user: user)
                case .routes:
                    RoutesListView(user: user)
                case .routeEditor(let id):
                    if let id {
                        if let route = user.routes.first(where: { $0.uuid == id }) {
                            RouteEditorView(user: user, route: route)
                        } else {
                            ContentUnavailableView("Recorrido no encontrado", systemImage: "map")
                        }
                    } else {
                        RouteEditorView(user: user, route: nil)
                    }
                case .profile:
                    ProfileView(user: user)
                case .rewards:
                    RewardsView(user: user)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Agregar mascota", systemImage: "plus") {
                        viewModel.isAddingPet = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: HomeDestination.profile) {
                        Label("Perfil", systemImage: "person.crop.circle")
                    }
                }
            }
            .sheet(isPresented: $viewModel.isAddingPet) {
                PetFormView(owner: user)
            }
        }
    }
}
