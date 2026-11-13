import SwiftUI

enum MaterialSort: String, CaseIterable, Identifiable {
    case newest = "Newest first"
    case name = "Name (A–Z)"
    case stockLow = "Lowest stock"
    case cost = "Highest cost"
    var id: String { rawValue }
}

struct InventoryListView: View {
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var router: AppRouter

    @State private var search = ""
    @State private var category = "All"
    @State private var sort: MaterialSort = .newest
    @State private var pendingDelete: Material? = nil
    @State private var stockTarget: Material? = nil
    @State private var stockText = ""

    private let categories = ["All"] + MaterialCategory.allCases.map(\.rawValue)

    private var filtered: [Material] {
        let query = search.trimmed
        let items = store.materials.filter { material in
            (category == "All" || material.category.rawValue == category) &&
            (query.isEmpty || material.name.localizedCaseInsensitiveContains(query))
        }
        switch sort {
        case .newest: return items.sorted { $0.createdAt > $1.createdAt }
        case .name: return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .stockLow: return items.sorted { $0.currentStock * $0.unit.toBaseFactor < $1.currentStock * $1.unit.toBaseFactor }
        case .cost: return items.sorted { $0.cost > $1.cost }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 12) {
                CKScreenHeader(title: "Inventory List", subtitle: "Manage your ingredients and costs.") {
                    Button {
                        router.push(.materialForm(nil), in: .inventory)
                    } label: {
                        Label("Add Material", systemImage: "plus")
                    }
                    .buttonStyle(.ckCompact)
                }
                .padding(.top, 12)

                HStack(spacing: 8) {
                    CKSearchField(placeholder: "Search ingredient...", text: $search)
                    CKFilterMenu(isActive: sort != .newest) {
                        Picker("Sort by", selection: $sort) {
                            ForEach(MaterialSort.allCases) { Text($0.rawValue).tag($0) }
                        }
                    }
                }

                CKCategoryPills(options: categories, selection: $category, columns: 5)
            }
            .padding(.horizontal, CKMetrics.hPadding)

            if filtered.isEmpty {
                ScrollView {
                    if store.materials.isEmpty {
                        CKEmptyState(icon: "shippingbox", title: "No materials yet",
                                     message: "Add the ingredients and packaging you buy to track costs and stock.",
                                     actionTitle: "Add Material") { router.push(.materialForm(nil), in: .inventory) }
                    } else {
                        CKEmptyState(icon: "magnifyingglass", title: "No matching materials",
                                     message: "Try a different search or category.")
                    }
                }
                .scrollDismissesKeyboard(.immediately)
            } else {
                List {
                    ForEach(filtered) { material in
                        MaterialRowView(material: material,
                                        onOpen: { router.push(.materialForm(material.id), in: .inventory) },
                                        onUpdateStock: {
                                            stockText = Fmt.number(material.currentStock)
                                            stockTarget = material
                                        })
                            .ckListRow()
                            .ckSwipeToDelete { pendingDelete = material }
                    }
                    Color.clear.frame(height: 8).ckListRow()
                }
                .listStyle(.plain)
                .refreshable { await store.refresh() }
                .scrollContentBackground(.hidden)
                .environment(\.defaultMinListRowHeight, 0)
                .scrollDismissesKeyboard(.immediately)
                .animation(.default, value: filtered)
            }
        }
        .ckScreenBackground(waveHeight: 110)
        .ckDeleteAlert("Material", item: $pendingDelete, name: { $0.name }) { material in
            withAnimation { store.deleteMaterial(id: material.id) }
        }
        .alert("Update Stock", isPresented: Binding(get: { stockTarget != nil }, set: { if !$0 { stockTarget = nil } }),
               presenting: stockTarget) { material in
            TextField("Current stock (\(material.unit.rawValue))", text: $stockText)
                .keyboardType(.decimalPad)
            Button("Cancel", role: .cancel) { stockTarget = nil }
            Button("Save") {
                if let value = Fmt.parse(stockText), value >= 0 {
                    store.updateStock(materialID: material.id, newStock: value)
                }
                stockTarget = nil
            }
        } message: { material in
            Text("Enter the current stock of \(material.name) in \(material.unit.rawValue). Negative values aren't allowed.")
        }
    }
}

struct MaterialRowView: View {
    let material: Material
    let onOpen: () -> Void
    let onUpdateStock: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                CKThumbnail(material: material, size: 58)
                VStack(alignment: .leading, spacing: 5) {
                    Text(material.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(CKColor.navy)
                        .lineLimit(1)
                    CKBadge(material.category)
                    HStack(spacing: 6) {
                        Text("Stock: \(material.stockLabel)")
                            .font(.system(size: 13))
                            .foregroundStyle(material.currentStock <= 0 ? CKColor.danger : CKColor.textSecondary)
                        Text("•").foregroundStyle(CKColor.textTertiary).font(.system(size: 11))
                        Text(material.priceLabel)
                            .font(.system(size: 12))
                            .foregroundStyle(CKColor.textTertiary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onOpen)

            VStack(alignment: .trailing) {
                Menu {
                    Button(action: onOpen) { Label("Edit Material", systemImage: "pencil") }
                    Button(action: onUpdateStock) { Label("Update Stock", systemImage: "number") }
                } label: {
                    CKMoreGlyph()
                }
                .accessibilityLabel("More actions for \(material.name)")
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CKColor.navy)
                    .padding(.trailing, 8)
                    .onTapGesture(perform: onOpen)
            }
            .frame(height: 58)
        }
        .ckCard(padding: 10)
        .accessibilityElement(children: .contain)
    }
}
