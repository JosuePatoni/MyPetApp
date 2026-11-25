import SwiftData
import SwiftUI

/// Pedido de placa personalizada ($100 MXN, pago simulado).
struct PlateOrderView: View {
    let pet: Pet
    @Bindable var owner: User

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PlateOrderViewModel

    init(pet: Pet, owner: User) {
        self.pet = pet
        self.owner = owner
        _viewModel = State(initialValue: PlateOrderViewModel(pet: pet, owner: owner))
    }

    var body: some View {
        Form {
            Section {
                let plateSize = 180.0
                let area = viewModel.shape.textArea
                Image(systemName: viewModel.shape.symbolName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: plateSize, height: plateSize)
                    .foregroundStyle(viewModel.color.color.gradient)
                    .overlay {
                        // El texto se encoge hasta 30 % para caber en la zona de cada forma, en vez de cortarse.
                        Text(viewModel.engraving)
                            .font(.headline.bold())
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .lineLimit(4)
                            .minimumScaleFactor(0.3)
                            .frame(width: plateSize * area.width, height: plateSize * area.height)
                            .offset(y: plateSize * area.offsetY)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("Vista previa de la placa"))
                    .accessibilityValue(Text(viewModel.engraving))
            }

            Section("Diseño") {
                Picker("Forma", selection: $viewModel.shape) {
                    ForEach(PlateShape.allCases) { shape in
                        Label {
                            Text(shape.title)
                        } icon: {
                            Image(systemName: shape.symbolName)
                        }
                        .tag(shape)
                    }
                }
                Picker("Color", selection: $viewModel.color) {
                    ForEach(PlateColor.allCases) { color in
                        Text(color.title).tag(color)
                    }
                }
                TextField("Texto grabado", text: $viewModel.engraving, axis: .vertical)
                    .lineLimit(2...3)
            }

            Section {
                TextField("Dirección de envío", text: $owner.address, axis: .vertical)
                    .textContentType(.fullStreetAddress)
                    .lineLimit(2...4)
            } header: {
                Text("Envío")
            } footer: {
                Text("Máximo \(PlateOrderViewModel.maxEngravingLength) caracteres grabados.")
            }

            Section {
                LabeledContent("Total", value: PlateOrderViewModel.price, format: .currency(code: "MXN"))
                Button {
                    Task { await viewModel.pay(for: pet, in: modelContext) }
                } label: {
                    if viewModel.isPaying {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Pagar \(PlateOrderViewModel.price, format: .currency(code: "MXN"))")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(!viewModel.canPay(owner: owner))
            } footer: {
                if let date = pet.plateOrderDate {
                    Text("Ya pediste una placa el \(date, format: .dateTime.day().month().year()). Pago simulado: no se cobra nada.")
                } else {
                    Text("Pago simulado: no se cobra nada.")
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .navigationTitle("Placa de \(pet.name)")
        .navigationBarTitleDisplayMode(.inline)
        .alert("¡Pedido confirmado!", isPresented: $viewModel.isConfirmed) {
            Button("Aceptar") { dismiss() }
        } message: {
            Text("La placa de \(pet.name) llegará en 5 a 7 días hábiles.")
        }
    }
}
