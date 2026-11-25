import SwiftUI

/// "Mis paseos": historial ordenable por fecha y + para iniciar uno nuevo.
struct WalksListView: View {
    let user: User

    @State private var sortOrder = SortOrder.reverse

    private var walks: [Walk] {
        user.walks.sorted {
            sortOrder == .forward ? $0.startDate < $1.startDate : $0.startDate > $1.startDate
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(walks) { walk in
                    WalkCard(walk: walk)
                }
            }
            .padding()
        }
        .overlay {
            if walks.isEmpty {
                ContentUnavailableView(
                    "Aún no hay paseos",
                    systemImage: "figure.walk",
                    description: Text("Toca + para iniciar tu primer paseo.")
                )
            }
        }
        .navigationTitle("Mis paseos")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("Ordenar", systemImage: "arrow.up.arrow.down") {
                    Picker("Fecha", selection: $sortOrder) {
                        Text("Más recientes primero").tag(SortOrder.reverse)
                        Text("Más antiguos primero").tag(SortOrder.forward)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: HomeDestination.newWalk) {
                    Label("Iniciar nuevo paseo", systemImage: "plus")
                }
            }
        }
    }
}
