import SwiftData
import SwiftUI

/// "Iniciar un nuevo paseo": mascotas, ruta (calculada o personalizada) e Iniciar.
struct NewWalkView: View {
    let user: User

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = WalkSessionViewModel()
    @State private var isPickingStart = false
    @State private var isPickingEnd = false

    private var pets: [Pet] {
        user.pets.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private var routes: [Route] {
        user.routes.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private var selectedPets: [Pet] {
        pets.filter { viewModel.selectedPetIDs.contains($0.uuid) }
    }

    var body: some View {
        Form {
            Section("Mascotas a pasear") {
                if pets.isEmpty {
                    Text("Agrega una mascota primero.")
                        .foregroundStyle(.secondary)
                }
                ForEach(pets) { pet in
                    Toggle(isOn: selectionBinding(for: pet)) {
                        Label(pet.name, systemImage: pet.species.symbolName)
                    }
                }
            }

            Section("Ruta") {
                Picker("Ruta", selection: $viewModel.customRoute) {
                    Text("Calculada por el sistema").tag(Route?.none)
                    ForEach(routes) { route in
                        Text(route.name).tag(Optional(route))
                    }
                }

                if let route = viewModel.customRoute {
                    LabeledContent("Inicio", value: route.startAddress)
                    LabeledContent("Final", value: route.endAddress)
                    LabeledContent("Distancia", value: Format.distance(route.distance))
                    routeStartStatus(route)
                } else {
                    Button {
                        isPickingStart = true
                    } label: {
                        LabeledContent("Ubicación inicial", value: viewModel.startLocation?.name ?? String(localized: "Mi ubicación"))
                    }
                    Button {
                        isPickingEnd = true
                    } label: {
                        LabeledContent("Ubicación final", value: viewModel.endLocation?.name ?? String(localized: "Elegir ubicación"))
                    }
                    if viewModel.isCalculating {
                        ProgressView("Calculando ruta…")
                    } else if let route = viewModel.calculatedRoute {
                        LabeledContent("Distancia", value: Format.distance(route.distance))
                        LabeledContent("Tiempo a pie", value: Format.duration(route.expectedTravelTime))
                    }
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            Section {
                Button("Iniciar", systemImage: "figure.walk") {
                    viewModel.startWalk(with: selectedPets)
                }
                .frame(maxWidth: .infinity)
                .disabled(!viewModel.canStart(with: selectedPets))
            }
        }
        .navigationTitle("Iniciar un nuevo paseo")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startLocationUpdates()
            if viewModel.selectedPetIDs.isEmpty, let first = pets.first {
                viewModel.selectedPetIDs = [first.uuid]
            }
        }
        .sheet(isPresented: $isPickingStart) {
            LocationPickerView(title: "Ubicación inicial") { location in
                viewModel.startLocation = location
                Task { await viewModel.calculateRoute() }
            }
        }
        .sheet(isPresented: $isPickingEnd) {
            LocationPickerView(title: "Ubicación final") { location in
                viewModel.endLocation = location
                Task { await viewModel.calculateRoute() }
            }
        }
        .fullScreenCover(isPresented: $viewModel.isShowingWalk) {
            NavigationStack {
                WalkInProgressView(viewModel: viewModel, user: user)
            }
        }
        .onChange(of: viewModel.didFinish) {
            if viewModel.didFinish {
                dismiss()
            }
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
                Label("Estás a \(Format.distance(distance)) del inicio. Acércate para comenzar.", systemImage: "location.slash")
                    .foregroundStyle(.orange)
            }
        } else {
            Label("Buscando tu ubicación…", systemImage: "location")
                .foregroundStyle(.secondary)
        }
    }
}
