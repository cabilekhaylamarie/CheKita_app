import SwiftUI

struct IngredientsStepView: View {
    @ObservedObject var vm: CreateProductViewModel
    @EnvironmentObject private var store: DataStore
    @State private var showAddMaterial = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ingredients")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(CKColor.navy)
                    Text("Select ingredients and enter the quantity used.")
                        .font(.system(size: 12))
                        .foregroundStyle(CKColor.textSecondary)
                }
                Spacer()
                Button {
                    showAddMaterial = true
                } label: {
                    Label("New", systemImage: "plus")
                }
                .buttonStyle(.ckSoft)
            }

            CKSearchField(placeholder: "Search ingredients...", text: $vm.ingredientSearch)

            VStack(spacing: 0) {
                if store.materials.isEmpty {
                    CKEmptyState(icon: "shippingbox", title: "No materials yet",
                                 message: "Add the ingredients you buy so CheKita can compute costs.",
                                 actionTitle: "Add Material") { showAddMaterial = true }
                } else if vm.filteredMaterials.isEmpty {
                    CKEmptyState(icon: "magnifyingglass", title: "No matching ingredients",
                                 message: "Try another name or add it as a new material.")
                } else {
                    ForEach(Array(vm.filteredMaterials.enumerated()), id: \.element.id) { index, material in
                        IngredientSelectRow(vm: vm, material: material)
                        if index < vm.filteredMaterials.count - 1 {
                            Divider().overlay(CKColor.border).padding(.leading, 52)
                        }
                    }
                }
            }
            .ckCard(padding: 8)

            if !vm.orphanIngredients.isEmpty {
                CKSectionCard(title: "Kept from original recipe",
                              subtitle: "These materials were removed from inventory; their last price is used.") {
                    ForEach(vm.orphanIngredients) { ingredient in
                        HStack {
                            Text("\(ingredient.materialEmoji) \(ingredient.materialName)")
                                .font(.system(size: 13))
                                .foregroundStyle(CKColor.navy)
                            Spacer()
                            Text(ingredient.quantityLabel)
                                .font(.system(size: 13))
                                .foregroundStyle(CKColor.textSecondary)
                            Text(Fmt.peso(ingredient.cost))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(CKColor.navy)
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "function")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CKColor.primary)
                    .frame(width: 34, height: 34)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Total Ingredient Cost")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(CKColor.navy)
                    Text("\(vm.builtIngredients.count) ingredient\(vm.builtIngredients.count == 1 ? "" : "s") selected")
                        .font(.system(size: 11))
                        .foregroundStyle(CKColor.textSecondary)
                }
                Spacer()
                Text(Fmt.peso(vm.totalIngredientCost))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(CKColor.primary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: CKMetrics.cardRadius).fill(CKColor.aqua))
            .animation(.snappy, value: vm.totalIngredientCost)

            if let error = vm.ingredientError {
                CKErrorText(message: error)
            }
        }
        .padding(.top, 4)
        .sheet(isPresented: $showAddMaterial) {
            NavigationStack {
                MaterialFormView(materialID: nil)
                    .toolbar(.hidden, for: .navigationBar)
            }
            .environmentObject(store)
        }
    }
}

private struct IngredientSelectRow: View {
    @ObservedObject var vm: CreateProductViewModel
    let material: Material

    private var selection: IngredientSelection { vm.selection(for: material) }

    private var quantityBinding: Binding<String> {
        Binding(
            get: { vm.selection(for: material).quantityText },
            set: { newValue in
                var updated = vm.selection(for: material)
                updated.quantityText = newValue
                vm.updateSelection(updated, for: material)
            }
        )
    }

    var body: some View {
        let current = selection
        let invalid = vm.showIngredientValidation && vm.hasInvalidQuantity(material)

        HStack(spacing: 8) {
            CKThumbnail(material: material, size: 38, radius: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(material.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CKColor.navy)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Text(material.priceLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(CKColor.textSecondary)
                    .lineLimit(1)
                if current.isSelected, vm.lineCost(for: material) > 0 {
                    Text("= \(Fmt.peso(vm.lineCost(for: material)))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(CKColor.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { vm.toggle(material) }

            CKSuffixField(placeholder: "0", text: quantityBinding, hasError: invalid, fieldWidth: 52) {
                Menu {
                    ForEach(material.unit.compatibleUnits) { unit in
                        Button {
                            var updated = vm.selection(for: material)
                            updated.unit = unit
                            vm.updateSelection(updated, for: material)
                        } label: {
                            if unit == current.unit {
                                Label(unit.displayName, systemImage: "checkmark")
                            } else {
                                Text(unit.displayName)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text(current.unit.rawValue)
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(CKColor.navy)
                    .padding(.horizontal, 7)
                    .frame(height: 38)
                    .contentShape(Rectangle())
                }
            }

            Button {
                vm.toggle(material)
            } label: {
                CKCheckbox(isOn: current.isSelected, size: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(current.isSelected ? "Deselect \(material.name)" : "Select \(material.name)")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(current.isSelected ? CKColor.aquaSoft : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
