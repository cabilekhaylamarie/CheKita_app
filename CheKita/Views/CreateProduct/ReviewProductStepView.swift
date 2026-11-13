import SwiftUI

struct ReviewProductStepView: View {
    @ObservedObject var vm: CreateProductViewModel

    var body: some View {
        let ingredients = vm.builtIngredients

        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Review Product")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(CKColor.navy)
                Text("Check the details below before saving.")
                    .font(.system(size: 12))
                    .foregroundStyle(CKColor.textSecondary)
            }

            CKSectionCard(title: "Product Details", trailing: {
                Button {
                    vm.step = .details
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .buttonStyle(.ckSmallOutline)
            }) {
                HStack(alignment: .top, spacing: 12) {
                    CKThumbnail(fileName: nil, assetName: nil,
                                emoji: EmojiGuesser.product(name: vm.name, category: vm.category ?? .others),
                                size: 64, tint: (vm.category ?? .others).badgeBackground)
                        .overlay {
                            if let image = vm.previewImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    VStack(spacing: 0) {
                        reviewRow("Product Name", vm.name.trimmed)
                        reviewRow("Category", vm.category?.rawValue ?? "—")
                        reviewRow("Description", vm.productDescription.trimmed.isEmpty ? "—" : vm.productDescription.trimmed, last: true)
                    }
                }
            }

            CKSectionCard(title: "Ingredients", trailing: {
                Button {
                    vm.step = .ingredients
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .buttonStyle(.ckSmallOutline)
            }) {
                VStack(spacing: 0) {
                    tableRow(["Ingredient", "Quantity", "Unit", "Cost (₱)"], header: true)
                    ForEach(ingredients) { ingredient in
                        tableRow([ingredient.materialName,
                                  Fmt.number(ingredient.quantity),
                                  ingredient.unit.label(for: ingredient.quantity),
                                  Fmt.peso(ingredient.cost).replacingOccurrences(of: "₱", with: "")])
                        Divider().overlay(CKColor.border)
                    }
                    HStack {
                        Text("Total Ingredient Cost")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(CKColor.navy)
                        Spacer()
                        Text(Fmt.peso(vm.totalIngredientCost))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(CKColor.primary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 9)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(CKColor.border, lineWidth: 1))
            }

            if !vm.builtOverheads.isEmpty {
                CKSectionCard(title: "Labor & Other Costs", trailing: {
                    Button {
                        vm.step = .profit
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .buttonStyle(.ckSmallOutline)
                }) {
                    VStack(spacing: 0) {
                        tableRow(["Cost", "Rate", "Basis", "Total (₱)"], header: true)
                        ForEach(vm.builtOverheads) { overhead in
                            tableRow([overhead.name,
                                      Fmt.peso(overhead.amount).replacingOccurrences(of: "₱", with: ""),
                                      overhead.basis == .perBatch ? "batch" : "piece",
                                      Fmt.peso(overhead.total(forYield: vm.calculated?.yield ?? 0))
                                        .replacingOccurrences(of: "₱", with: "")])
                            Divider().overlay(CKColor.border)
                        }
                        HStack {
                            Text("Total Labor & Other Costs")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(CKColor.navy)
                            Spacer()
                            Text(Fmt.peso(vm.calculated?.overheadCost ?? vm.totalOverheadCost))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(CKColor.primary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 9)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(CKColor.border, lineWidth: 1))
                }
            }

            CKSectionCard(title: "Profit Summary", trailing: {
                Button {
                    vm.step = .profit
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .buttonStyle(.ckSmallOutline)
            }) {
                if let summary = vm.calculated {
                    VStack(spacing: 0) {
                        CKInfoRow(label: vm.yieldMode == .target ? "Target Yield (pieces)" : "Actual Yield (pieces)",
                                  value: "\(summary.yield) \(vm.yieldUnit)")
                        CKInfoRow(label: "Selling Price", value: Fmt.peso(summary.suggestedSRP))
                        CKInfoRow(label: "Profit Margin", value: Fmt.percent(summary.desiredProfitPercent.rounded()))
                        CKInfoRow(label: "Ingredient Cost", value: Fmt.peso(summary.ingredientCost))
                        if summary.overheadCost > 0 {
                            CKInfoRow(label: "Labor & Other Costs", value: Fmt.peso(summary.overheadCost))
                        }
                        CKInfoRow(label: "Total Cost", value: Fmt.peso(summary.totalCost))
                        CKInfoRow(label: "Cost per Piece", value: Fmt.peso(summary.costPerPiece))
                        CKInfoRow(label: "Suggested SRP", value: Fmt.peso(summary.suggestedSRP), highlight: true)
                        CKInfoRow(label: "Estimated Profit", value: Fmt.peso(summary.estimatedProfit), highlight: true, showDivider: false)
                    }
                } else {
                    Text("Go back to the Profit Calculator and tap Calculate.")
                        .font(.system(size: 13))
                        .foregroundStyle(CKColor.warning)
                }
            }
        }
        .padding(.top, 4)
        .onAppear {
            if vm.calculated == nil { _ = vm.calculate() }
        }
    }

    private func reviewRow(_ label: String, _ value: String, last: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(CKColor.textSecondary)
                    .frame(width: 88, alignment: .leading)
                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CKColor.navy)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 6)
            if !last { Divider().overlay(CKColor.border) }
        }
    }

    private func tableRow(_ values: [String], header: Bool = false) -> some View {
        HStack(spacing: 4) {
            Text(values[0]).frame(maxWidth: .infinity, alignment: .leading)
            Text(values[1]).frame(width: 58, alignment: .trailing)
            Text(values[2]).frame(width: 40, alignment: .center)
            Text(values[3]).frame(width: 64, alignment: .trailing)
        }
        .font(.system(size: 12, weight: header ? .semibold : .regular))
        .foregroundStyle(CKColor.navy)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(header ? CKColor.aqua : Color.white)
    }
}
