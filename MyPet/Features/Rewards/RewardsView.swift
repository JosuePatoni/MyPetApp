import SwiftData
import SwiftUI

/// "Recompensas" (wireframes 14–16): plan, filtro de marcas, cupones conseguidos y próxima recompensa.
struct RewardsView: View {
    let user: User

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Brand.order) private var brands: [Brand]
    @State private var openCoupon: Reward?
    @State private var isShowingPlan = false

    /// Con plan Básico se muestran todas las marcas; el filtro solo aplica en Pro.
    private var coupons: [Reward] {
        let hidden = user.isPro ? Set(user.hiddenBrandCodes) : []
        return user.rewards
            .filter { !hidden.contains($0.brand?.code ?? "") }
            .sorted { $0.unlockedAt > $1.unlockedAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Marcas que se muestran")
                    .font(.title2.bold())
                brandFilter

                Text("Cupones conseguidos")
                    .font(.title2.bold())
                    .padding(.top, 8)

                if coupons.isEmpty {
                    Text("Aún no tienes cupones. ¡Sal a pasear para desbloquearlos!")
                        .foregroundStyle(.secondary)
                }
                ForEach(Array(coupons.enumerated()), id: \.element.id) { item in
                    let coupon = item.element
                    let isLocked = coupon.isPro && !user.isPro
                    RewardCouponCard(
                        reward: coupon,
                        isLocked: isLocked,
                        fill: item.offset.isMultiple(of: 2) ? MyPetPalette.mint : MyPetPalette.yellow
                    ) {
                        if isLocked {
                            isShowingPlan = true
                        } else {
                            openCoupon = coupon
                        }
                    }
                }

                nextRewardCard
            }
            .padding()
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Recompensas")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingPlan = true
                } label: {
                    Text(user.isPro ? "Pro" : "Básico")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(MyPetPalette.yellow, in: .capsule)
                        .overlay { Capsule().strokeBorder(MyPetPalette.teal, lineWidth: 1.5) }
                }
                .accessibilityLabel(user.isPro ? "Plan Pro" : "Plan Básico")
                .accessibilityHint("Cambiar de plan")
            }
        }
        .sheet(item: $openCoupon) { coupon in
            CouponDetailView(reward: coupon)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isShowingPlan) {
            ProPlanView(user: user)
        }
        .onAppear(perform: evaluateRewards)
    }

    /// Cuadrícula de 2 columnas con casillas; con plan Básico se ve bloqueada y todas marcadas.
    private var brandFilter: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 0), GridItem(.flexible(), spacing: 0)], spacing: 0) {
                ForEach(brands) { brand in
                    let isVisible = !user.isPro || !user.hiddenBrandCodes.contains(brand.code)
                    Button {
                        toggle(brand)
                    } label: {
                        Label {
                            Text(brand.name)
                        } icon: {
                            Image(systemName: isVisible ? "checkmark.square.fill" : "square")
                                .foregroundStyle(user.isPro ? MyPetPalette.teal : .gray)
                        }
                        .font(.title3)
                        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                        .padding(.horizontal, 16)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .disabled(!user.isPro)
                    .accessibilityAddTraits(isVisible ? .isSelected : [])
                }
            }

            if !user.isPro {
                Divider()
                Button {
                    isShowingPlan = true
                } label: {
                    Label("Filtro de marcas disponible en Pro", systemImage: "lock")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain)
            }
        }
        .background(user.isPro ? Color.clear : Color.gray.opacity(0.12), in: .rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(user.isPro ? MyPetPalette.teal : .gray, lineWidth: 1.5)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var nextRewardCard: some View {
        if let next = RewardService(context: modelContext).nextReward(for: user) {
            let requirement = next.code.requirement
            HStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.gray)
                    .frame(width: 64)
                    .accessibilityHidden(true)
                Rectangle()
                    .fill(MyPetPalette.teal)
                    .frame(width: 1.5)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Próxima recompensa")
                        .font(.title3.bold())
                    Text(requirement.unlockText)
                        .font(.subheadline)
                    ProgressView(value: min(next.progress, requirement.goal), total: requirement.goal)
                        .tint(MyPetPalette.turquoise)
                    Text(requirement.progressText(next.progress))
                        .font(.headline)
                }
            }
            .padding()
            .fixedSize(horizontal: false, vertical: true)
            .background(Color.gray.opacity(0.12), in: .rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(MyPetPalette.teal, lineWidth: 1.5)
            }
            .accessibilityElement(children: .combine)
        } else {
            Label("¡Ya desbloqueaste todas las recompensas!", systemImage: "star.fill")
                .foregroundStyle(MyPetPalette.teal)
        }
    }

    private func toggle(_ brand: Brand) {
        if let index = user.hiddenBrandCodes.firstIndex(of: brand.code) {
            user.hiddenBrandCodes.remove(at: index)
        } else {
            user.hiddenBrandCodes.append(brand.code)
        }
    }

    /// Entrega cupones de paseos hechos antes de que existieran las recompensas.
    private func evaluateRewards() {
        RewardService(context: modelContext).evaluate(for: user)
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
        }
    }
}
