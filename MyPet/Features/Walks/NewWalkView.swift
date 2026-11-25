import MapKit
import SwiftData
import SwiftUI

/// Formulario para elegir las mascotas, preparar la ruta e iniciar el paseo.
struct NewWalkView: View {
    let user: User

    let onStarted: (WalkSessionViewModel) -> Void

    @State private var viewModel = WalkSessionViewModel()
    @State private var isPlanningRoute = false

    private var pets: [Pet] {
        user.pets.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    private var routes: [Route] {
        user.routes.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    private var selectedPets: [Pet] {
        pets.filter { viewModel.selectedPetIDs.contains($0.uuid) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Iniciar un nuevo paseo")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)

                fieldTitle("Mascotas a pasear", color: MyPetPalette.yellow)

                if pets.isEmpty {
                    Label("Agrega una mascota primero.", systemImage: "pawprint")
                        .foregroundStyle(.secondary)
                } else {
                    Menu {
                        ForEach(pets) { pet in
                            Toggle(isOn: selectionBinding(for: pet)) {
                                Label(pet.name, systemImage: pet.species.symbolName)
                            }
                        }
                    } label: {
                        field(
                            selectedPets.isEmpty
                                ? String(localized: "Elegir mascotas")
                                : selectedPets.map(\.name).formatted(.list(type: .and)),
                            icon: "chevron.down"
                        )
                    }
                    .menuActionDismissBehavior(.disabled)
                    .accessibilityLabel("Mascotas a pasear")
                    .accessibilityValue(
                        selectedPets.map(\.name).formatted(.list(type: .and))
                    )
                }

                if !routes.isEmpty || viewModel.customRoute != nil {
                    Picker("Ruta", selection: $viewModel.customRoute) {
                        Text("Calculada por el sistema")
                            .tag(Route?.none)

                        ForEach(routes) { route in
                            Text(route.name)
                                .tag(Optional(route))
                        }
                    }
                    .pickerStyle(.menu)
                }

                if let route = viewModel.customRoute {
                    labeledLocation("Ubicación inicial", value: route.startAddress)
                    labeledLocation("Ubicación final", value: route.endAddress)
                    LabeledContent("Distancia", value: Format.distance(route.distance))
                    routeStartStatus(route)
                } else {
                    Button {
                        isPlanningRoute = true
                    } label: {
                        VStack(alignment: .leading, spacing: 22) {
                            labeledLocation(
                                "Ubicación inicial",
                                value: viewModel.startLocation?.name
                                    ?? String(localized: "Mi ubicación")
                            )

                            labeledLocation(
                                "Ubicación final",
                                value: viewModel.endLocation?.name
                                    ?? String(localized: "Elegir ubicación")
                            )
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Abre el mapa para elegir el inicio y el destino")

                    if viewModel.isCalculating {
                        ProgressView("Calculando ruta…")
                    } else if let route = viewModel.calculatedRoute {
                        Map(initialPosition: .automatic, interactionModes: []) {
                            SuggestedPath(coordinates: viewModel.calculatedPath)
                        }
                        .frame(height: 160)
                        .clipShape(.rect(cornerRadius: 12))
                        .accessibilityHidden(true)

                        LabeledContent(
                            "Distancia",
                            value: Format.distance(route.distance)
                        )
                        LabeledContent(
                            "Tiempo a pie",
                            value: Format.duration(route.expectedTravelTime)
                        )
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                Button {
                    guard !viewModel.isShowingWalk else { return }
                    viewModel.startWalk(with: selectedPets)
                    onStarted(viewModel)
                } label: {
                    Text("Iniciar paseo")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(MyPetPalette.teal)
                .buttonBorderShape(.roundedRectangle(radius: 14))
                .disabled(!viewModel.canStart(with: selectedPets))
            }
            .padding(20)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startLocationUpdates()

            if viewModel.selectedPetIDs.isEmpty, let first = pets.first {
                viewModel.selectedPetIDs = [first.uuid]
            }
        }
        .sheet(isPresented: $isPlanningRoute) {
            RoutePlannerView(viewModel: viewModel)
        }
        .onDisappear {
            if viewModel.walkStartDate == nil { viewModel.stopLocationUpdates() }
        }
    }

    private func fieldTitle(_ title: LocalizedStringKey, color: Color) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color, in: RoundedRectangle(cornerRadius: 8))
    }

    private func field(_ value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Text(value)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

            Spacer()

            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 48)
        .background(Color(uiColor: .systemBackground))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(MyPetPalette.teal, lineWidth: 1.5)
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
    }

    private func labeledLocation(_ title: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldTitle(title, color: MyPetPalette.apricot)
            field(value, icon: "mappin.circle")
        }
    }

    private func selectionBinding(for pet: Pet) -> Binding<Bool> {
        Binding {
            viewModel.selectedPetIDs.contains(pet.uuid)
        } set: { isOn in
            if isOn {
                viewModel.selectedPetIDs.insert(pet.uuid)
            } else {
                viewModel.selectedPetIDs.remove(pet.uuid)
            }
        }
    }

    @ViewBuilder
    private func routeStartStatus(_ route: Route) -> some View {
        if let distance = viewModel.distanceToStart(of: route) {
            if distance <= WalkSessionViewModel.maxDistanceFromRouteStart {
                Label("Estás en el punto de inicio", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Label(
                    "Estás a \(Format.distance(distance)) del inicio. Acércate para comenzar.",
                    systemImage: "location.slash"
                )
                .foregroundStyle(.orange)
            }
        } else {
            Label("Buscando tu ubicación…", systemImage: "location")
                .foregroundStyle(.secondary)
        }
    }
}
