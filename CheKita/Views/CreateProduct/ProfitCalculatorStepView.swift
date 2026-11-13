import SwiftUI

struct ProfitCalculatorStepView: View {
    @ObservedObject var vm: CreateProductViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Profit Calculator")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(CKColor.navy)
                Text("Compute your product cost and profit.")
                    .font(.system(size: 12))
                    .foregroundStyle(CKColor.textSecondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                productField
                YieldModeToggle(selection: $vm.yieldMode)
                yieldField
                OtherCostsEditor(vm: vm)
                sellingPriceField
                costBreakdown

                Button {
                    Keyboard.dismiss()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { _ = vm.calculate() }
                } label: {
                    Label("Calculate", systemImage: "equal.square")
                }
                .buttonStyle(.ckPrimary(height: 46))
                .padding(.horizontal, 40)

                if let error = vm.ingredientError {
                    CKErrorText(message: error)
                }

                if let summary = vm.calculated {
                    CKSummaryPanel(summary: summary)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    Text("Enter the yield and your selling price, then tap Calculate.")
                        .font(.system(size: 12))
                        .foregroundStyle(CKColor.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            .ckCard(padding: 14)
        }
        .padding(.top, 4)
    }

    // MARK: Product

    private var productField: some View {
        VStack(alignment: .leading, spacing: 6) {
            CKFieldLabel("Product")
            Menu {
                Button {
                    vm.step = .details
                } label: {
                    Label("Edit product details", systemImage: "pencil")
                }
                Button {
                    vm.step = .ingredients
                } label: {
                    Label("Edit ingredients", systemImage: "list.bullet")
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "shippingbox")
                        .foregroundStyle(CKColor.textSecondary)
                    Text(vm.name.trimmed.isEmpty ? "Untitled product" : vm.name.trimmed)
                        .font(.system(size: 15))
                        .foregroundStyle(CKColor.navy)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CKColor.navy)
                }
                .padding(.horizontal, 14)
                .frame(height: CKMetrics.fieldHeight)
                .background(RoundedRectangle(cornerRadius: CKMetrics.fieldRadius).fill(Color.white))
                .overlay(RoundedRectangle(cornerRadius: CKMetrics.fieldRadius).stroke(CKColor.fieldBorder, lineWidth: 1))
            }
        }
    }

    // MARK: Yield

    private var yieldField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(vm.yieldMode == .target ? "Target Yield (pieces)" : "Actual Yield (pieces)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(CKColor.navy)
                Spacer()
                CKSuffixField(placeholder: "0", text: $vm.activeYieldText, keyboard: .numberPad,
                              hasError: vm.yieldError != nil, fieldWidth: 64) {
                    Menu {
                        ForEach(CreateProductViewModel.yieldUnits, id: \.self) { unit in
                            Button(unit) { vm.yieldUnit = unit }
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Text(vm.yieldUnit).font(.system(size: 12, weight: .medium))
                            Image(systemName: "chevron.down").font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(CKColor.navy)
                        .padding(.horizontal, 8)
                        .frame(height: 38)
                    }
                }
            }
            if let error = vm.yieldError { CKErrorText(message: error) }
        }
    }

    // MARK: Selling price

    private var sellingPriceField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Selling Price Target")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(CKColor.navy)
                    Text("Price per \(vm.yieldUnit == "pcs" ? "piece" : "unit")")
                        .font(.system(size: 11))
                        .foregroundStyle(CKColor.textSecondary)
                }
                Spacer()
                CKSuffixField(placeholder: "0.00", text: $vm.sellingPriceText, keyboard: .decimalPad,
                              hasError: vm.sellingPriceError != nil, fieldWidth: 80) {
                    Text("₱")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(CKColor.navy)
                        .padding(.horizontal, 10)
                }
            }
            if let error = vm.sellingPriceError {
                CKErrorText(message: error)
            } else if vm.calculated == nil, vm.sellingPrice != nil, vm.profitPercent != 0 {
                Text("That price is about \(Fmt.percent(vm.profitPercent.rounded())) profit.")
                    .font(.system(size: 11))
                    .foregroundStyle(CKColor.primary)
            }
        }
    }

    // MARK: Running cost totals

    private var costBreakdown: some View {
        VStack(spacing: 5) {
            line("Total Ingredient Cost", Fmt.peso(vm.totalIngredientCost))
            if vm.totalOverheadCost > 0 {
                line("Labor & Other Costs", Fmt.peso(vm.totalOverheadCost))
            }
            Divider().overlay(CKColor.border)
            HStack {
                Text("Total Cost")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CKColor.navy)
                Spacer()
                Text(Fmt.peso(vm.totalCost))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(CKColor.primary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
        }
        .animation(.snappy, value: vm.totalCost)
    }

    private func line(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(CKColor.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CKColor.navy)
                .monospacedDigit()
        }
    }
}

// MARK: - Labor and other costs

/// Lets the user add labor, gas/electricity, packaging and delivery to the costing.
struct OtherCostsEditor: View {
    @ObservedObject var vm: CreateProductViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Labor & Other Costs")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(CKColor.navy)
                    Text("Optional — added on top of your ingredients.")
                        .font(.system(size: 11))
                        .foregroundStyle(CKColor.textSecondary)
                }
                Spacer()
                Menu {
                    ForEach(OverheadCost.presets) { preset in
                        Button {
                            withAnimation { vm.addOverhead(preset) }
                        } label: {
                            Label(preset.name, systemImage: preset.icon)
                        }
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CKColor.primary)
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .background(RoundedRectangle(cornerRadius: 8).fill(CKColor.aqua))
                }
                .accessibilityLabel("Add another cost")
            }

            if vm.overheadDrafts.isEmpty {
                Text("Tap Add to include labor, gas or packaging in your cost per piece.")
                    .font(.system(size: 12))
                    .foregroundStyle(CKColor.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(CKColor.aquaSoft))
            } else {
                VStack(spacing: 8) {
                    ForEach(vm.overheadDrafts) { draft in
                        OtherCostRow(draft: vm.binding(for: draft),
                                     yieldLabel: vm.yieldUnit,
                                     onDelete: { withAnimation { vm.removeOverhead(draft) } })
                    }
                }
            }

            if let error = vm.overheadError {
                CKErrorText(message: error)
            }
        }
    }
}

private struct OtherCostRow: View {
    @Binding var draft: OverheadDraft
    let yieldLabel: String
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: draft.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(CKColor.primary)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(CKColor.aqua))

                TextField("Cost name", text: $draft.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(CKColor.navy)
                    .textInputAutocapitalization(.words)

                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(CKColor.navy)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(CKColor.pill))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(draft.name)")
            }

            HStack(spacing: 8) {
                CKSuffixField(placeholder: "0.00", text: $draft.amountText, keyboard: .decimalPad, fieldWidth: 76) {
                    Text("₱")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CKColor.navy)
                        .padding(.horizontal, 8)
                }
                Picker("Basis", selection: $draft.basis) {
                    ForEach(OverheadBasis.allCases) { basis in
                        Text(basis == .perBatch ? "Per Batch" : "Per \(yieldLabel == "pcs" ? "Piece" : "Unit")")
                            .tag(basis)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(CKColor.aquaSoft))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(CKColor.border, lineWidth: 1))
    }
}

// MARK: - Yield mode toggle

struct YieldModeToggle: View {
    @Binding var selection: YieldMode

    var body: some View {
        HStack(spacing: 4) {
            ForEach(YieldMode.allCases) { mode in
                let isSelected = mode == selection
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selection = mode }
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.white : CKColor.navy)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(RoundedRectangle(cornerRadius: 8).fill(isSelected ? CKColor.primary : Color.clear))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 10).fill(CKColor.pill))
    }
}
