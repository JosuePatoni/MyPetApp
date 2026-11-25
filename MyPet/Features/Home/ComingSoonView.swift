import SwiftUI

struct ComingSoonView: View {
    let title: LocalizedStringResource

    var body: some View {
        ContentUnavailableView(
            "Próximamente",
            systemImage: "hammer",
            description: Text("Esta sección estará disponible pronto.")
        )
        .navigationTitle(Text(title))
    }
}
