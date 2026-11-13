import SwiftUI

struct ProductListView: View {
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var router: AppRouter

    @State private var search = ""
    @State private var category = "All"
    @State private var sort: ProductSort = .newest
    @State private var pendingDelete: Product? = nil
    @State private var recordTarget: IdentifiedValue<UUID>? = nil
    @State private var saleTarget: IdentifiedValue<UUID>? = nil

    private let categories = ["All"] + ProductCategory.allCases.map(\.rawValue)

    private var filtered: [Product] {
        let query = search.trimmed
        let items = store.products.filter { product in
            (category == "All" || product.category.rawValue == category) &&
            (query.isEmpty || product.name.localizedCaseInsensitiveContains(query)
                || product.description.localizedCaseInsensitiveContains(query))
        }
        switch sort {
        case .newest: return items.sorted { $0.createdAt > $1.createdAt }
        case .name: return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .stockLow: return items.sorted { $0.stock < $1.stock }
        case .stockHigh: return items.sorted { $0.stock > $1.stock }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 12) {
                CKScreenHeader(title: "Products", subtitle: "Manage your food products.") {
                    Button {
                        router.startCreateProduct()
                    } label: {
                        Label("Add Product", systemImage: "plus")
                    }
                    .buttonStyle(.ckCompact)
                }
                .padding(.top, 12)

                HStack(spacing: 8) {
                    CKSearchField(placeholder: "Search products...", text: $search)
                    CKFilterMenu(isActive: sort != .newest) {
                        Picker("Sort by", selection: $sort) {
                            ForEach(ProductSort.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    }
                }

                CKCategoryPills(options: categories, selection: $category, columns: 4)
            }
            .padding(.horizontal, CKMetrics.hPadding)

            if filtered.isEmpty {
                ScrollView {
                    if store.products.isEmpty {
                        CKEmptyState(icon: "bag", title: "No products yet",
                                     message: "Create your first food product to start computing costs and profit.",
                                     actionTitle: "Add Product") { router.startCreateProduct() }
                    } else {
                        CKEmptyState(icon: "magnifyingglass", title: "No matching products",
                                     message: "Try a different search or category.")
                    }
                }
                .scrollDismissesKeyboard(.immediately)
            } else {
                List {
                    ForEach(filtered) { product in
                        ProductRowView(product: product,
                                       onOpen: { router.push(.productDetail(product.id), in: .products) },
                                       onEdit: { router.startEditProduct(product.id) },
                                       onRecord: { recordTarget = IdentifiedValue(value: product.id) },
                                       onSell: { saleTarget = IdentifiedValue(value: product.id) })
                            .ckListRow()
                            .ckSwipeToDelete { pendingDelete = product }
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
        .ckDeleteAlert("Product", item: $pendingDelete, name: { $0.name }) { product in
            withAnimation { store.deleteProduct(id: product.id) }
        }
        .sheet(item: $recordTarget) { target in
            RecordProductionView(productID: target.value, onViewProduct: {
                recordTarget = nil
                router.push(.productDetail(target.value), in: .products)
            })
            .environmentObject(store)
            .environmentObject(router)
        }
        .sheet(item: $saleTarget) { target in
            RecordSaleView(productID: target.value, onViewProduct: {
                saleTarget = nil
                router.push(.productDetail(target.value), in: .products)
            })
            .environmentObject(store)
            .environmentObject(router)
        }
    }
}

enum ProductSort: String, CaseIterable, Identifiable {
    case newest = "Newest first"
    case name = "Name (A–Z)"
    case stockLow = "Stock (low to high)"
    case stockHigh = "Stock (high to low)"
    var id: String { rawValue }
}

struct ProductRowView: View {
    let product: Product
    let onOpen: () -> Void
    let onEdit: () -> Void
    let onRecord: () -> Void
    let onSell: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                CKThumbnail(product: product, size: 58)
                VStack(alignment: .leading, spacing: 5) {
                    Text(product.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(CKColor.navy)
                        .lineLimit(1)
                    CKBadge(product.category)
                    Text(product.stockLabel)
                        .font(.system(size: 13))
                        .foregroundStyle(product.stock == 0 ? CKColor.warning : CKColor.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onOpen)

            VStack(alignment: .trailing) {
                Menu {
                    Button(action: onOpen) { Label("View Details", systemImage: "doc.text.magnifyingglass") }
                    Button(action: onEdit) { Label("Edit Product", systemImage: "pencil") }
                    Button(action: onRecord) { Label("Record Production", systemImage: "plus.square.on.square") }
                    Button(action: onSell) { Label("Record Sale", systemImage: "cart.badge.plus") }
                        .disabled(product.stock <= 0)
                } label: {
                    CKMoreGlyph()
                }
                .accessibilityLabel("More actions for \(product.name)")
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
        .accessibilityAction(named: "Open") { onOpen() }
    }
}
