import SwiftUI

struct PetWalkDetail: View {
    let walk: Walk
    let pet: Pet
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    row("Fecha", walk.startDate.formatted(date: .abbreviated, time: .omitted))
                    row("Hora de inicio", walk.startDate.formatted(date: .omitted, time: .standard))
                    row("Hora final", walk.endDate?.formatted(date: .omitted, time: .standard) ?? "—")
                    row("Ubicación inicial", walk.startAddress)
                    row("Ubicación final", walk.endAddress)
                    row("Duración", Format.duration(walk.duration))
                    row("Paradas pet friendly", walk.petFriendlyStops.formatted(.list(type: .and)))
                    row("Mascota", pet.name)
                    if let calories = Walk.calories(walking: walk.distance, weight: pet.weight) {
                        row("Calorías quemadas", "\(Int(calories.rounded())) kcal")
                    } else { row("Calorías quemadas", String(localized: "Peso sin registrar")) }
                }.padding()
            }
            .navigationTitle("Detalle del paseo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar", systemImage: "xmark.circle") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func row(_ title: LocalizedStringKey, _ value: String) -> some View {
        VStack {
            LabeledContent(title) { Text(value.isEmpty ? "—" : value) }
                .padding(.vertical, 8)
            Divider()
        }
    }
}
