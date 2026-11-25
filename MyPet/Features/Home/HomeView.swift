import SwiftData
import SwiftUI

struct HomeView: View {
    @Bindable var user: User

    @Query(sort: \Achievement.order) private var achievements: [Achievement]
    @State private var viewModel = HomeViewModel()
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        NavigationStack(path: $user.navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .center, spacing: 12) {
                        Text("¡Hola, \(user.username)!")
                            .font(.largeTitle.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)

                        NavigationLink(value: HomeDestination.profile) {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 32, weight: .medium))
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Perfil de usuario")
                    }

                    Text("¿Comenzamos con un paseo?")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    HStack {
                        Text("Mis mascotas")
                            .font(.title2.bold())

                        Spacer()

                        Button {
                            viewModel.isAddingPet = true
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 32, weight: .medium))
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Agregar mascota")
                    }

                    PetCarousel(
                        pets: viewModel.pets(of: user),
                        selection: $viewModel.selectedPetIndex
                    ) {
                        viewModel.isAddingPet = true
                    }

                    shortcutLayout {
                        NavigationLink(value: HomeDestination.walks) {
                            HomeTile(
                                title: "Mis paseos",
                                systemImage: "figure.walk",
                                fill: MyPetPalette.yellow
                            )
                        }

                        NavigationLink(value: HomeDestination.routes) {
                            HomeTile(
                                title: "Mis recorridos",
                                systemImage: "map",
                                fill: MyPetPalette.turquoise
                            )
                        }
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: HomeDestination.reminders) {
                        HomeTile(
                            title: "Mis recordatorios",
                            systemImage: "alarm",
                            fill: MyPetPalette.mint,
                            isHorizontal: true
                        )
                    }
                    .buttonStyle(.plain)

                    Text("Mis logros")
                        .font(.title2.bold())

                    AchievementsRow(
                        achievements: achievements,
                        unlockedCodes: viewModel.unlockedCodes(of: user)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("My Pet")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: HomeDestination.self) { destination in
                destinationView(for: destination)
            }
            .sheet(isPresented: $viewModel.isAddingPet) {
                PetFormView(owner: user)
            }
        }
    }

    private var shortcutLayout: AnyLayout {
        if dynamicTypeSize.isAccessibilitySize {
            return AnyLayout(VStackLayout(spacing: 12))
        }
        return AnyLayout(HStackLayout(spacing: 12))
    }

    @ViewBuilder
    private func destinationView(for destination: HomeDestination) -> some View {
        switch destination {
        case .reminders:
            RemindersListView(user: user)

        case .pet(let id), .petReminder(let id), .petQR(let id), .petPlate(let id):
            if let pet = viewModel.pet(withID: id, of: user) {
                switch destination {
                case .petReminder:
                    ReminderSettingsView(pet: pet)
                case .petQR:
                    PetQRView(pet: pet, owner: user)
                case .petPlate:
                    PlateOrderView(pet: pet, owner: user)
                default:
                    PetDetailView(pet: pet, owner: user)
                }
            } else {
                ContentUnavailableView(
                    "Mascota no encontrada",
                    systemImage: "pawprint"
                )
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
                    ContentUnavailableView(
                        "Recorrido no encontrado",
                        systemImage: "map"
                    )
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
}
