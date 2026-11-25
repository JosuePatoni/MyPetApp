import SwiftData
import SwiftUI

struct HomeView: View {
    @Bindable var user: User

    @Query(sort: \Achievement.order) private var achievements: [Achievement]
    @State private var viewModel = HomeViewModel()
    @State private var activeWalk: WalkSessionViewModel?
    @State private var showingWalk = false
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

                    if let activeWalk, activeWalk.walkStartDate != nil {
                        walkBanner(activeWalk)
                    } else {
                        Text("¿Comenzamos con un paseo?")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text(user.role.petsTitle)
                            .font(.title2.bold())

                        Spacer()

                        // Sin mascotas, el carrusel ya muestra su propio botón "Agregar mascota".
                        if !user.pets.isEmpty {
                            Button("Agregar mascota") {
                                viewModel.isAddingPet = true
                            }
                            .font(.headline)
                            .buttonStyle(.bordered)
                            .tint(MyPetPalette.teal)
                        }
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
        .fullScreenCover(isPresented: $showingWalk) {
            if let activeWalk {
                NavigationStack {
                    WalkInProgressView(viewModel: activeWalk, user: user) {
                        showingWalk = false
                    }
                }
            }
        }
        .onChange(of: activeWalk?.isShowingWalk) { _, isRunning in
            guard isRunning == false, let ended = activeWalk else { return }
            showingWalk = false
            activeWalk = nil
            if ended.didFinish { user.navigationPath = [.walks] }
        }
    }

    private func walkBanner(_ walk: WalkSessionViewModel) -> some View {
        Button {
            showingWalk = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "mappin.circle.fill")
                    .font(.largeTitle).foregroundStyle(MyPetPalette.teal)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Paseo en curso").font(.headline)
                    Text(walk.walkPets.map(\.name).formatted(.list(type: .and)))
                    Text("Ver detalles").font(.subheadline.weight(.semibold))
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding(16)
            .foregroundStyle(.black)
            .background(MyPetPalette.mint, in: .rect(cornerRadius: 16))
            .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(MyPetPalette.teal, lineWidth: 1.5) }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Abre el mapa y los datos del paseo actual")
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
                    // Una ruta guardada de antes de cambiar de rol no debe abrir la placa a un paseador.
                    if user.role == .owner {
                        PlateOrderView(pet: pet, owner: user)
                    } else {
                        ContentUnavailableView("Solo los dueños pueden pedir placas", systemImage: "tag.slash")
                    }
                default:
                    PetDetailView(pet: pet, owner: user, isWalking: activeWalk?.walkPets.contains { $0.uuid == id } == true)
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
            if let activeWalk {
                walkBanner(activeWalk).padding()
            } else {
                NewWalkView(user: user) { started in
                    activeWalk = started
                    user.navigationPath = []
                    showingWalk = true
                }
            }

        case .routes:
            RoutesListView(user: user, activeRouteID: activeWalk?.customRoute?.uuid)

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
            ProfileView(user: user, activeWalk: activeWalk)

        case .rewards:
            RewardsView(user: user)
        }
    }
}
