import SwiftData
import SwiftUI

/// "Seleccionar paseador": cards de los paseadores (cuentas de este dispositivo + ejemplos); tocar uno lo marca como "Mi paseador".
struct WalkerPickerView: View {
    let user: User

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \User.username) private var users: [User]

    // ponytail: filtra en memoria (SwiftData no filtra bien enums en #Predicate); con servidor, paginar en el backend
    /// Mejor calificados primero.
    private var walkers: [User] {
        users
            .filter { $0.role == .walker && $0.persistentModelID != user.persistentModelID }
            .sorted { ($0.averageRating ?? 0, $0.walkerWalkCount) > ($1.averageRating ?? 0, $1.walkerWalkCount) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                if walkers.isEmpty {
                    ContentUnavailableView(
                        "Aún no hay paseadores",
                        systemImage: "figure.walk",
                        description: Text("Cuando alguien se registre como paseador en este dispositivo, aparecerá aquí.")
                    )
                }
                ForEach(Array(walkers.enumerated()), id: \.element.id) { item in
                    let walker = item.element
                    Button {
                        select(walker)
                    } label: {
                        WalkerCard(
                            walker: walker,
                            isSelected: user.selectedWalker?.persistentModelID == walker.persistentModelID,
                            fill: item.offset.isMultiple(of: 2) ? MyPetPalette.mint : MyPetPalette.yellow
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Lo marca como tu paseador")
                }
            }
            .padding()
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Seleccionar paseador")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if user.selectedWalker != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Quitar", role: .destructive) { select(nil) }
                }
            }
        }
    }

    private func select(_ walker: User?) {
        user.selectedWalker = walker
        do {
            try modelContext.save()
            if walker != nil {
                dismiss()
            }
        } catch {
            modelContext.rollback()
        }
    }
}
