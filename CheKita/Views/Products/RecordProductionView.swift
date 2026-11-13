import SwiftUI

/// Records a produced batch: adds the quantity to product stock, optionally deducts
/// ingredients from inventory, saves a production record and updates Reports.
struct RecordProductionView: View {
    let productID: UUID
    /// Called from the success dialog's "View Product" button.
    let onViewProduct: () -> Void

    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss

    @State private var quantityText = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var deductMaterials = true
    @State private var quantityError: String? = nil
    @State private var recorded: ProductionRecord? = nil
    @State private var didPrefill = false

    private var product: Product? { store.product(id: productID) }
    private var quantity: Int? {
        guard let value = Fmt.parseInt(quantityText), value > 0 else { return nil }
        return value
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                if let product {
                    form(product)
                } else {
                    CKEmptyState(icon: "bag", title: "Product not found", message: "This product may have been deleted.")
                    Spacer()
                }
            }
            .background(Color.white.ignoresSafeArea())

            if let recorded, let product {
                CKSuccessModal(
                    title: "Production Recorded Successfully!",
                    highlight: "\(recorded.quantity) \(recorded.yieldUnit) of \(product.name)",
                    message: "have been added to your stock.",
                    primaryTitle: "Done",
                    secondaryTitle: "View Product",
                    onPrimary: { dismiss() },
                    onSecondary: onViewProduct
                )
                .zIndex(2)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: recorded)
        .interactiveDismissDisabled(recorded != nil)
        .onAppear {
            guard !didPrefill, let product else { return }
            didPrefill = true
            quantityText = String(product.effectiveYield)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Record Production")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(CKColor.navy)
                Text("Add a finished batch to your stock.")
                    .font(.system(size: 13))
                    .foregroundStyle(CKColor.textSecondary)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(CKColor.navy)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(CKColor.aqua))
            }
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, CKMetrics.hPadding)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private func form(_ product: Product) -> some View {
        let qty = quantity ?? 0
        let cost = store.productionCost(for: product, quantity: qty)
        let shortages = deductMaterials && qty > 0 ? store.shortages(for: product, quantity: qty) : []

        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    CKThumbnail(product: product, size: 54)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(product.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(CKColor.navy)
                        CKBadge(product.category)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Available Stock")
                            .font(.system(size: 11))
                            .foregroundStyle(CKColor.textSecondary)
                        Text(product.stockLabel)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(CKColor.navy)
                    }
                }
                .ckCard(padding: 12)

                VStack(alignment: .leading, spacing: 6) {
                    CKFieldLabel("Production Quantity", required: true)
                    HStack(spacing: 10) {
                        stepButton("minus") { adjust(by: -1) }
                            .disabled(qty <= 1)
                        CKSuffixField(placeholder: "0", text: $quantityText, keyboard: .numberPad,
                                      hasError: quantityError != nil, fieldWidth: 90) {
                            Text(product.yieldUnit)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(CKColor.navy)
                                .padding(.horizontal, 10)
                        }
                        stepButton("plus") { adjust(by: 1) }
                        Spacer()
                    }
                    if let quantityError {
                        CKErrorText(message: quantityError)
                    } else {
                        Text("One batch yields \(product.effectiveYield) \(product.yieldUnit). New stock: \(product.stock + qty) \(product.yieldUnit)")
                            .font(.system(size: 12))
                            .foregroundStyle(CKColor.textSecondary)
                    }
                }
                .onChange(of: quantityText) { _, _ in quantityError = nil }

                VStack(alignment: .leading, spacing: 6) {
                    CKFieldLabel("Production Date", required: true)
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(CKColor.textSecondary)
                        DatePicker("Production Date", selection: $date, in: ...Date(), displayedComponents: .date)
                            .labelsHidden()
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .frame(height: CKMetrics.fieldHeight)
                    .overlay(RoundedRectangle(cornerRadius: CKMetrics.fieldRadius).stroke(CKColor.fieldBorder, lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: 6) {
                    CKFieldLabel("Notes (Optional)")
                    CKTextArea(icon: "note.text", placeholder: "e.g. Batch for weekend orders", text: $notes)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $deductMaterials) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Deduct ingredients from inventory")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(CKColor.navy)
                            Text("Uses the recipe scaled to this quantity.")
                                .font(.system(size: 12))
                                .foregroundStyle(CKColor.textSecondary)
                        }
                    }
                    .tint(CKColor.primary)

                    if !shortages.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Not enough stock for some ingredients", systemImage: "exclamationmark.triangle.fill")
                                .font(.system(size: 12, weight: .semibold))
                            ForEach(shortages, id: \.self) { line in
                                Text("• \(line)")
                                    .font(.system(size: 12))
                            }
                            Text("Stock will be set to 0 for these items.")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(CKColor.warning)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 10).fill(CKColor.warningSoft))
                    }
                }
                .ckCard(padding: 12)

                VStack(spacing: 6) {
                    HStack {
                        Text("Production Cost")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(CKColor.navy)
                        Spacer()
                        Text(Fmt.peso(cost.totalCost))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(CKColor.primary)
                            .monospacedDigit()
                    }
                    Divider().overlay(CKColor.aquaStrong)
                    summaryLine("Cost per Piece", Fmt.peso(cost.costPerPiece))
                    summaryLine("Suggested SRP", Fmt.peso(cost.suggestedSRP))
                    summaryLine("Estimated Profit", Fmt.peso(cost.estimatedProfit))
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: CKMetrics.cardRadius).fill(CKColor.aqua))
            }
            .padding(.horizontal, CKMetrics.hPadding)
            .padding(.bottom, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CKBottomBar {
                HStack(spacing: 10) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.ckOutline)
                    Button {
                        confirm(product)
                    } label: {
                        Label("Confirm", systemImage: "checkmark")
                    }
                    .buttonStyle(.ckPrimary)
                }
            }
        }
    }

    private func summaryLine(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundStyle(CKColor.navy)
            Spacer()
            Text(value).font(.system(size: 14, weight: .bold)).foregroundStyle(CKColor.primary)
        }
    }

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(CKColor.primary)
                .frame(width: 38, height: 38)
                .background(RoundedRectangle(cornerRadius: 8).fill(CKColor.aqua))
        }
        .buttonStyle(.plain)
    }

    private func adjust(by delta: Int) {
        let current = Fmt.parseInt(quantityText) ?? 0
        quantityText = String(max(1, current + delta))
    }

    private func confirm(_ product: Product) {
        Keyboard.dismiss()
        guard !quantityText.trimmed.isEmpty else {
            quantityError = "Production quantity is required."
            return
        }
        guard let qty = quantity else {
            quantityError = "Enter a whole number greater than 0."
            return
        }
        guard qty <= 100_000 else {
            quantityError = "That quantity looks too large. Enter up to 100,000."
            return
        }
        if let record = store.recordProduction(productID: product.id, quantity: qty, date: date,
                                               notes: notes.trimmed, deductMaterials: deductMaterials) {
            recorded = record
        } else {
            quantityError = "Couldn't record this production. Please try again."
        }
    }
}
