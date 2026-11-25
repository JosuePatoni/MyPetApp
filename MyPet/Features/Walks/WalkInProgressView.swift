import MapKit
import SwiftData
import SwiftUI

/// "Paseo en curso…": mapa en tiempo real, horas, distancia, calorías y Finalizar viaje.
struct WalkInProgressView: View {
    let viewModel: WalkSessionViewModel
    let user: User

    @Environment(\.modelContext) private var modelContext
    @State private var isConfirmingDiscard = false

    var body: some View {
        VStack(spacing: 0) {
            Map(initialPosition: .userLocation(fallback: .automatic)) {
                UserAnnotation()
                if viewModel.plannedPath.count > 1 {
                    SuggestedPath(coordinates: viewModel.plannedPath)
                }
                if let end = viewModel.plannedPath.last {
                    Marker("Final", systemImage: "flag.checkered", coordinate: end)
                        .tint(.red)
                }
                if viewModel.traveled.count > 1 {
                    MapPolyline(coordinates: viewModel.traveled)
                        .stroke(.orange, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                }
            }
            .mapControls { MapUserLocationButton() }

            VStack(spacing: 12) {
                Text(viewModel.walkPets.map(\.name).formatted(.list(type: .and)))
                    .font(.headline)

                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                    if let start = viewModel.walkStartDate {
                        row("Hora de inicio", Text(start, format: .dateTime.hour().minute()))
                        row("Tiempo", Text(start, style: .timer))
                    }
                    if let arrival = viewModel.expectedArrival {
                        row("Llegada estimada", Text(arrival, format: .dateTime.hour().minute()))
                    }
                    row("Distancia", Text(Format.distance(viewModel.traveledDistance)))
                    row("Calorías quemadas", Text(Format.calories(of: viewModel.walkPets, walking: viewModel.traveledDistance)))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button {
                    Task { await viewModel.finishWalk(user: user, in: modelContext) }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Finalizar viaje")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isSaving)
            }
            .padding()
        }
        .navigationTitle("Paseo en curso…")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Descartar", role: .destructive) { isConfirmingDiscard = true }
            }
        }
        .confirmationDialog("¿Descartar este paseo?", isPresented: $isConfirmingDiscard, titleVisibility: .visible) {
            Button("Descartar", role: .destructive, action: viewModel.discardWalk)
        } message: {
            Text("No se guardará ni dará experiencia.")
        }
    }

    private func row(_ label: LocalizedStringResource, _ value: Text) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
            value
        }
    }
}
