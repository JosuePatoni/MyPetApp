import SwiftData
import SwiftUI

/// "Hazte Pro": beneficios y compra simulada ($49 MXN al mes), o volver a Básico.
struct ProPlanView: View {
    let user: User

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ProPlanViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(MyPetPalette.yellow, MyPetPalette.teal)
                            .accessibilityHidden(true)
                        Text("MyPet Pro")
                            .font(.title.bold())
                        Text(user.isPro ? "Tu plan actual es Pro." : "Tu plan actual es Básico.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }

                Section("Beneficios") {
                    Label("Abre todos los cupones Pro", systemImage: "ticket")
                    Label("Elige qué marcas ver en Recompensas", systemImage: "line.3.horizontal.decrease.circle")
                }

                Section {
                    LabeledContent("Precio", value: "\(ProPlanViewModel.monthlyPrice.formatted(.currency(code: "MXN"))) / mes")
                    if user.isPro {
                        Button("Volver a plan Básico", role: .destructive) {
                            if viewModel.cancel(user, in: modelContext) {
                                dismiss()
                            }
                        }
                    } else {
                        Button {
                            Task {
                                if await viewModel.subscribe(user, in: modelContext) {
                                    dismiss()
                                }
                            }
                        } label: {
                            if viewModel.isPaying {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Pagar \(ProPlanViewModel.monthlyPrice, format: .currency(code: "MXN")) al mes")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .disabled(viewModel.isPaying)
                    }
                } footer: {
                    Text("Pago simulado: no se cobra nada.")
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .interactiveDismissDisabled(viewModel.isPaying)
        }
    }
}
