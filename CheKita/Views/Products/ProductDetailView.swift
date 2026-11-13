import SwiftUI

struct ProductDetailView: View {
    let productID: UUID

    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var session: SessionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showRecordProduction = false
    @State private var showRecordSale = false

    var body: some View {
        Group {
            if let product = store.product(id: productID) {
                content(product)
            } else {
                VStack(spacing: 0) {
                    CKNavHeader(title: "Product Details", onBack: { dismiss() })
                    CKEmptyState(icon: "bag", title: "Product not found",
                                 message: "This product may have been deleted.")
                    Spacer()
                }
            }
        }
        .ckScreenBackground(waveHeight: 100)
    }

    @ViewBuilder
    private func content(_ product: Product) -> some View {
        let summary = store.summary(for: product)
        let ingredients = store.resolvedIngredients(for: product)
        let history = store.records(forProduct: product.id)
        let soldHistory = store.sales(forProduct: product.id)

        VStack(spacing: 0) {
            CKNavHeader(title: "Product Details", onBack: { dismiss() }) {
                Menu {
                    Button { router.startEditProduct(product.id) } label: { Label("Edit Product", systemImage: "pencil") }
                    Button { showRecordProduction = true } label: { Label("Record Production", systemImage: "plus.square.on.square") }
                    Button { showRecordSale = true } label: { Label("Record Sale", systemImage: "cart.badge.plus") }
                } label: {
                    CKMoreGlyph()
                        .frame(width: 38, height: 38)
                }
                .accessibilityLabel("More actions")
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    CKThumbnail(fileName: product.imageFileName, assetName: product.imageAssetName,
                                base64: product.imageData, cacheKey: "p-\(product.id)-\(product.updatedAt.timeIntervalSince1970)",
                                emoji: product.emoji,
                                width: nil, height: 170, radius: 14,
                                tint: product.category.badgeBackground)

                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(product.name)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(CKColor.navy)
                            CKBadge(product.category)
                        }
                        Spacer(minLength: 8)
                        VStack(alignment: .trailing, spacing: 8) {
                            Button {
                                router.startEditProduct(product.id)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .buttonStyle(.ckSoft)
                            (Text("\(product.stock) \(product.yieldUnit)").fontWeight(.bold).foregroundColor(CKColor.navy)
                             + Text(" (stock)").foregroundColor(CKColor.textSecondary))
                                .font(.system(size: 13))
                        }
                    }

                    CKSectionCard(title: "Description") {
                        Text(product.description.isEmpty ? "No description added." : product.description)
                            .font(.system(size: 13))
                            .foregroundStyle(product.description.isEmpty ? CKColor.textTertiary : CKColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    CKSectionCard(title: "Ingredients") {
                        if ingredients.isEmpty {
                            Text("No ingredients yet.")
                                .font(.system(size: 13))
                                .foregroundStyle(CKColor.textTertiary)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(ingredients.enumerated()), id: \.element.id) { index, ingredient in
                                    HStack(spacing: 10) {
                                        CKIngredientIcon(emoji: ingredient.materialEmoji,
                                                         assetName: store.material(id: ingredient.materialID)?.imageAssetName,
                                                         fileName: store.material(id: ingredient.materialID)?.imageFileName,
                                                         base64: store.material(id: ingredient.materialID)?.imageData,
                                                         cacheKey: "mi-\(ingredient.materialID)",
                                                         size: 28)
                                        Text(ingredient.materialName)
                                            .font(.system(size: 13))
                                            .foregroundStyle(CKColor.navy)
                                        Spacer()
                                        Text(ingredient.quantityLabel)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(CKColor.navy)
                                    }
                                    .padding(.vertical, 7)
                                    if index < ingredients.count - 1 {
                                        Divider().overlay(CKColor.border)
                                    }
                                }
                            }
                        }
                    }

                    if !product.overheadList.isEmpty {
                        CKSectionCard(title: "Labor & Other Costs",
                                      subtitle: "Added on top of the ingredients") {
                            VStack(spacing: 0) {
                                ForEach(Array(product.overheadList.enumerated()), id: \.element.id) { index, item in
                                    HStack(spacing: 10) {
                                        Image(systemName: item.icon)
                                            .font(.system(size: 13))
                                            .foregroundStyle(CKColor.primary)
                                            .frame(width: 28, height: 28)
                                            .background(Circle().fill(CKColor.aqua))
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(item.name)
                                                .font(.system(size: 13))
                                                .foregroundStyle(CKColor.navy)
                                            Text(item.amountLabel)
                                                .font(.system(size: 11))
                                                .foregroundStyle(CKColor.textSecondary)
                                        }
                                        Spacer()
                                        Text(Fmt.peso(item.total(forYield: product.effectiveYield)))
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(CKColor.navy)
                                    }
                                    .padding(.vertical, 7)
                                    if index < product.overheadList.count - 1 {
                                        Divider().overlay(CKColor.border)
                                    }
                                }
                            }
                        }
                    }

                    CKSectionCard(title: "Profit Information") {
                        VStack(spacing: 0) {
                            CKInfoRow(label: product.yieldLabel, value: "\(product.effectiveYield) \(product.yieldUnit)")
                            CKInfoRow(label: "Profit Margin", value: Fmt.percent(product.desiredProfitPercent.rounded()))
                            CKInfoRow(label: "Ingredient Cost", value: Fmt.peso(summary.ingredientCost))
                            if summary.overheadCost > 0 {
                                CKInfoRow(label: "Labor & Other Costs", value: Fmt.peso(summary.overheadCost))
                            }
                            CKInfoRow(label: "Total Cost", value: Fmt.peso(summary.totalCost))
                            CKInfoRow(label: "Cost per Piece", value: Fmt.peso(summary.costPerPiece))
                            CKInfoRow(label: "Suggested SRP", value: Fmt.peso(summary.suggestedSRP), highlight: true)
                            CKInfoRow(label: "Estimated Profit", value: Fmt.peso(summary.estimatedProfit), highlight: true, showDivider: false)
                        }
                    }

                    if !soldHistory.isEmpty {
                        let sold = soldHistory.reduce(0) { $0 + $1.quantity }
                        let earned = soldHistory.reduce(0.0) { $0 + $1.profit }
                        CKSectionCard(title: "Sales History",
                                      subtitle: "\(sold) \(product.yieldUnit) sold · \(Fmt.peso(earned)) profit") {
                            VStack(spacing: 0) {
                                ForEach(Array(soldHistory.prefix(5).enumerated()), id: \.element.id) { index, sale in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(Fmt.longDate(sale.date))
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundStyle(CKColor.navy)
                                            Text("\(sale.quantityLabel) × \(Fmt.peso(sale.unitPrice))\(sale.customer.isEmpty ? "" : " · \(sale.customer)")")
                                                .font(.system(size: 12))
                                                .foregroundStyle(CKColor.textSecondary)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 1) {
                                            Text(Fmt.peso(sale.revenue))
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundStyle(CKColor.navy)
                                            Text("+\(Fmt.peso(sale.profit))")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundStyle(CKColor.primary)
                                        }
                                    }
                                    .padding(.vertical, 7)
                                    if index < min(soldHistory.count, 5) - 1 {
                                        Divider().overlay(CKColor.border)
                                    }
                                }
                            }
                        }
                    }

                    if !history.isEmpty {
                        CKSectionCard(title: "Production History", subtitle: "\(history.count) batch\(history.count == 1 ? "" : "es") recorded") {
                            VStack(spacing: 0) {
                                ForEach(Array(history.prefix(5).enumerated()), id: \.element.id) { index, record in
                                    Button {
                                        router.push(.recipeReport(record.id))
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(Fmt.longDate(record.date))
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundStyle(CKColor.navy)
                                                Text("Yield: \(record.yieldLabel)")
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(CKColor.textSecondary)
                                            }
                                            Spacer()
                                            Text(Fmt.peso(record.estimatedProfit))
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundStyle(CKColor.primary)
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(CKColor.textTertiary)
                                        }
                                        .padding(.vertical, 7)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    if index < min(history.count, 5) - 1 {
                                        Divider().overlay(CKColor.border)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, CKMetrics.hPadding)
                .padding(.top, 4)
                .padding(.bottom, 16)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                CKBottomBar {
                    HStack(spacing: 10) {
                        Button {
                            showRecordSale = true
                        } label: {
                            Label("Record Sale", systemImage: "cart.badge.plus")
                        }
                        .buttonStyle(CKOutlineButtonStyle(fontSize: 14))
                        .disabled(product.stock <= 0)
                        .opacity(product.stock <= 0 ? 0.5 : 1)

                        Button {
                            showRecordProduction = true
                        } label: {
                            Label("Record Production", systemImage: "plus.square.on.square")
                        }
                        .buttonStyle(.ckPrimary(height: CKMetrics.buttonHeight, fontSize: 14))
                    }
                }
            }
        }
        .sheet(isPresented: $showRecordProduction) {
            RecordProductionView(productID: product.id, onViewProduct: { showRecordProduction = false })
                .environmentObject(store)
                .environmentObject(router)
                .environmentObject(session)
        }
        .sheet(isPresented: $showRecordSale) {
            RecordSaleView(productID: product.id, onViewProduct: { showRecordSale = false })
                .environmentObject(store)
                .environmentObject(router)
                .environmentObject(session)
        }
    }
}
