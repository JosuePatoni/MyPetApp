import SwiftUI

struct HomeTile: View {
    let title: LocalizedStringKey
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(.fill.tertiary, in: .rect(cornerRadius: 16))
    }
}
