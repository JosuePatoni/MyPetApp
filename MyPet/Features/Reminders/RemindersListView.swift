import SwiftUI

/// "Mis recordatorios": un recordatorio por cada perro o gato del usuario.
struct RemindersListView: View {
    let user: User

    private var pets: [Pet] {
        user.pets
            .filter(\.species.canBeWalked)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        List(pets) { pet in
            NavigationLink(value: HomeDestination.petReminder(pet.uuid)) {
                VStack(alignment: .leading, spacing: 4) {
                    Label(pet.name, systemImage: pet.species.symbolName)
                        .font(.headline)
                    if let reminder = pet.reminder {
                        ReminderSummary(reminder: reminder)
                    } else {
                        Text("Sin recordatorio")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .overlay {
            if pets.isEmpty {
                ContentUnavailableView(
                    "Sin mascotas para pasear",
                    systemImage: "pawprint",
                    description: Text("Agrega un perro o un gato para crear recordatorios.")
                )
            }
        }
        .navigationTitle("Mis recordatorios")
    }
}
