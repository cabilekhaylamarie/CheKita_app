import SwiftUI

/// Records an actual sale: lowers the product's stock, saves the sale to Firestore and
/// feeds the Reports screen with real revenue and profit (not just estimates).
struct RecordSaleView: View {
    let productID: UUID
    /// Called from the success dialog's "View Product" button.
    let onViewProduct: () -> Void

    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var quantityText = "1"
    @State private var priceText = ""
    @State private var date = Date()
    @State private var channel: SaleChannel = .walkIn
    @State private var customer = ""
    @State private var notes = ""
    @State private var quantityError: String?
    @State private var priceError: String?
    @State private var recorded: SaleRecord?
    @State private var didPrefill = false

    private var product: Product? { store.product(id: productID) }
    private var quantity: Int? {
        guard let value = Fmt.parseInt(quantityText), value > 0 else { return nil }
        return value
    }
    private var unitPrice: Double? {
        guard let value = Fmt.parse(priceText), value >= 0 else { return nil }
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

            if let recorded {
                CKSuccessModal(
                    title: "Sale Recorded Successfully!",
                    highlight: "\(recorded.quantityLabel) of \(recorded.productName)",
                    message: "\(Fmt.peso(recorded.revenue)) earned · \(Fmt.peso(recorded.profit)) profit",
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
            quantityText = product.stock > 0 ? "1" : "0"
            let suggested = store.suggestedPrice(for: product)
            priceText = suggested > 0 ? String(format: "%.2f", suggested) : ""
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Record Sale")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(CKColor.navy)
                Text("Log what you actually sold.")
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
        let price = unitPrice ?? 0
        let unitCost = store.costPerPiece(for: product)
        let revenue = price * Double(qty)
        let cost = unitCost * Double(qty)
        let profit = revenue - cost

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
                            .foregroundStyle(product.stock <= 0 ? CKColor.danger : CKColor.navy)
                    }
                }
                .ckCard(padding: 12)

                if product.stock <= 0 {
                    Label("No stock left for this product. Record a production first.",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(CKColor.warning)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 10).fill(CKColor.warningSoft))
                }

                VStack(alignment: .leading, spacing: 6) {
                    CKFieldLabel("Quantity Sold", required: true)
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
                        Text("Stock after this sale: \(max(0, product.stock - qty)) \(product.yieldUnit)")
                            .font(.system(size: 12))
                            .foregroundStyle(CKColor.textSecondary)
                    }
                }
                .onChange(of: quantityText) { _, _ in quantityError = nil }

                VStack(alignment: .leading, spacing: 6) {
                    CKFieldLabel("Selling Price per \(product.yieldUnit == "pcs" ? "Piece" : "Unit")", required: true)
                    HStack(spacing: 10) {
                        CKSuffixField(placeholder: "0.00", text: $priceText, keyboard: .decimalPad,
                                      hasError: priceError != nil, fieldWidth: 90) {
                            Text("₱")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(CKColor.navy)
                                .padding(.horizontal, 10)
                        }
                        Button("Use Suggested") {
                            priceText = String(format: "%.2f", store.suggestedPrice(for: product))
                            priceError = nil
                        }
                        .buttonStyle(.ckSoft)
                        Spacer()
                    }
                    if let priceError {
                        CKErrorText(message: priceError)
                    } else {
                        Text("Suggested SRP: \(Fmt.peso(store.suggestedPrice(for: product))) · Cost: \(Fmt.peso(unitCost)) each")
                            .font(.system(size: 12))
                            .foregroundStyle(CKColor.textSecondary)
                    }
                }
                .onChange(of: priceText) { _, _ in priceError = nil }

                VStack(alignment: .leading, spacing: 6) {
                    CKFieldLabel("Date of Sale", required: true)
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(CKColor.textSecondary)
                        DatePicker("Date of Sale", selection: $date, in: ...Date(), displayedComponents: .date)
                            .labelsHidden()
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .frame(height: CKMetrics.fieldHeight)
                    .overlay(RoundedRectangle(cornerRadius: CKMetrics.fieldRadius).stroke(CKColor.fieldBorder, lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: 6) {
                    CKFieldLabel("Sold Through")
                    HStack(spacing: 6) {
                        ForEach(SaleChannel.allCases) { option in
                            let isSelected = option == channel
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) { channel = option }
                            } label: {
                                VStack(spacing: 3) {
                                    Image(systemName: option.icon)
                                        .font(.system(size: 14))
                                    Text(option.rawValue)
                                        .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .foregroundStyle(isSelected ? Color.white : CKColor.navy)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected ? CKColor.primary : CKColor.pill))
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    CKFieldLabel("Customer (Optional)")
                    CKTextField(icon: "person", placeholder: "e.g. Aling Nena", text: $customer, capitalization: .words)
                }

                VStack(alignment: .leading, spacing: 6) {
                    CKFieldLabel("Notes (Optional)")
                    CKTextArea(icon: "note.text", placeholder: "e.g. Paid via GCash", text: $notes)
                }

                VStack(spacing: 6) {
                    HStack {
                        Text("Total Sales")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(CKColor.navy)
                        Spacer()
                        Text(Fmt.peso(revenue))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(CKColor.primary)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    }
                    Divider().overlay(CKColor.aquaStrong)
                    summaryLine("Cost of Goods", Fmt.peso(cost))
                    summaryLine("Actual Profit", Fmt.peso(profit), highlight: true)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: CKMetrics.cardRadius).fill(CKColor.aqua))
                .animation(.snappy, value: revenue)
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

    private func summaryLine(_ label: String, _ value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundStyle(CKColor.navy)
            Spacer()
            Text(value)
                .font(.system(size: highlight ? 16 : 14, weight: .bold))
                .foregroundStyle(CKColor.primary)
                .monospacedDigit()
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
            quantityError = "Quantity sold is required."
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
        if qty > product.stock {
            quantityError = "You only have \(product.stockLabel) in stock. Record a production first."
            return
        }
        guard !priceText.trimmed.isEmpty else {
            priceError = "Selling price is required."
            return
        }
        guard let price = unitPrice, price > 0 else {
            priceError = "Enter a selling price greater than ₱0."
            return
        }

        if let sale = store.recordSale(productID: product.id, quantity: qty, unitPrice: price,
                                       date: date, channel: channel, customer: customer, notes: notes) {
            recorded = sale
        } else {
            quantityError = "Couldn't record this sale. Please try again."
        }
    }
}
