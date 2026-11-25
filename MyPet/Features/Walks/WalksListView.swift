import SwiftUI

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
            LazyVStack(alignment: .leading, spacing: 16) {
                Text("Ordenar por fecha").font(.headline)

                HStack(spacing: 0) {
                    sortButton("Más recientes", order: .reverse)
                    sortButton("Más antiguos", order: .forward)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(MyPetPalette.teal, lineWidth: 1.5)
                        .allowsHitTesting(false)
                }

                if user.walks.isEmpty {
                    ContentUnavailableView(
                        "Aún no hay paseos", systemImage: "figure.walk",
                        description: Text("Toca + para iniciar tu primer paseo.")
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(Array(walks.enumerated()), id: \.element.id) { item in
                        WalkCard(walk: item.element,
                                 headerColor: item.offset.isMultiple(of: 2) ? MyPetPalette.mint : MyPetPalette.yellow)
                    }
                }
            }
            .padding()
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Mis paseos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: HomeDestination.newWalk) {
                    Image(systemName: "plus.circle").font(.title2)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("Iniciar un nuevo paseo")
            }
        }
    }

    private func sortButton(_ title: LocalizedStringKey, order: SortOrder) -> some View {
        let selected = sortOrder == order
        return Button {
            sortOrder = order
        } label: {
            Text(title)
                .font(.subheadline.weight(selected ? .bold : .regular))
                .foregroundStyle(selected ? Color.black : Color.primary)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(selected ? MyPetPalette.turquoise : Color.clear,
                            in: RoundedRectangle(cornerRadius: 14))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
