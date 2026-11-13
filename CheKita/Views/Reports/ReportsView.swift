import SwiftUI

enum ReportSort: String, CaseIterable, Identifiable {
    case newest = "Newest first"
    case oldest = "Oldest first"
    case profit = "Highest profit"
    case yield = "Highest yield"
    var id: String { rawValue }
}

/// Reports has two sides: what was produced, and what was actually sold.
enum ReportTab: String, CaseIterable, Identifiable {
    case production = "Production"
    case sales = "Sales"
    var id: String { rawValue }
}

struct ReportsView: View {
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var router: AppRouter

    @State private var tab: ReportTab = .production
    @State private var search = ""
    @State private var category = "All"
    @State private var sort: ReportSort = .newest
    @State private var pendingDelete: ProductionRecord?
    @State private var pendingSaleDelete: SaleRecord?

    private let categories = ["All"] + ProductCategory.allCases.map(\.rawValue)

    private var filteredRecords: [ProductionRecord] {
        let items = store.report.filtered(category: category, search: search)
        switch sort {
        case .newest: return items.sorted { $0.date > $1.date }
        case .oldest: return items.sorted { $0.date < $1.date }
        case .profit: return items.sorted { $0.estimatedProfit > $1.estimatedProfit }
        case .yield: return items.sorted { $0.quantity > $1.quantity }
        }
    }

    private var filteredSales: [SaleRecord] {
        let items = store.salesReport.filtered(category: category, search: search)
        switch sort {
        case .newest: return items.sorted { $0.date > $1.date }
        case .oldest: return items.sorted { $0.date < $1.date }
        case .profit: return items.sorted { $0.profit > $1.profit }
        case .yield: return items.sorted { $0.quantity > $1.quantity }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 12) {
                CKScreenHeader(title: "Reports", subtitle: "View your production history and reports.") {
                    CKUserChip()
                }
                .padding(.top, 12)

                ReportTabPicker(selection: $tab)

                HStack(spacing: 8) {
                    CKSearchField(placeholder: tab == .production ? "Search product..." : "Search product or customer...",
                                  text: $search)
                    CKFilterMenu(isActive: sort != .newest) {
                        Picker("Sort by", selection: $sort) {
                            ForEach(ReportSort.allCases) { Text($0.rawValue).tag($0) }
                        }
                    }
                }

                CKCategoryPills(options: categories, selection: $category, columns: 4)

                if tab == .sales, !filteredSales.isEmpty {
                    salesTotals
                }
            }
            .padding(.horizontal, CKMetrics.hPadding)

            switch tab {
            case .production: productionList
            case .sales: salesList
            }
        }
        .ckScreenBackground(waveHeight: 110)
        .animation(.easeInOut(duration: 0.2), value: tab)
    }

    // MARK: Production

    @ViewBuilder
    private var productionList: some View {
        if filteredRecords.isEmpty {
            ScrollView {
                if store.records.isEmpty {
                    CKEmptyState(icon: "chart.bar", title: "No production yet",
                                 message: "Open a product and tap Record Production to start building your reports.",
                                 actionTitle: "Go to Products") { router.select(.products) }
                } else {
                    CKEmptyState(icon: "magnifyingglass", title: "No matching reports",
                                 message: "Try a different search or category.")
                }
            }
            .scrollDismissesKeyboard(.immediately)
        } else {
            List {
                ForEach(filteredRecords) { record in
                    ReportRowView(record: record) {
                        router.push(.recipeReport(record.id), in: .reports)
                    }
                    .ckListRow()
                    .ckSwipeToDelete { pendingDelete = record }
                }
                Color.clear.frame(height: 8).ckListRow()
            }
            .listStyle(.plain)
            .refreshable { await store.refresh() }
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 0)
            .scrollDismissesKeyboard(.immediately)
            .animation(.default, value: filteredRecords)
            .ckDeleteAlert("Report", item: $pendingDelete,
                           name: { "the \($0.productName) report from \(Fmt.longDate($0.date))" }) { record in
                withAnimation { store.deleteRecord(id: record.id) }
            }
        }
    }

    // MARK: Sales

    @ViewBuilder
    private var salesList: some View {
        if filteredSales.isEmpty {
            ScrollView {
                if store.sales.isEmpty {
                    CKEmptyState(icon: "cart", title: "No sales yet",
                                 message: "Open a product and tap Record Sale to track your real income and profit.",
                                 actionTitle: "Go to Products") { router.select(.products) }
                } else {
                    CKEmptyState(icon: "magnifyingglass", title: "No matching sales",
                                 message: "Try a different search or category.")
                }
            }
            .scrollDismissesKeyboard(.immediately)
        } else {
            List {
                ForEach(filteredSales) { sale in
                    SaleRowView(sale: sale) {
                        router.push(.productDetail(sale.productID), in: .reports)
                    }
                    .ckListRow()
                    .ckSwipeToDelete { pendingSaleDelete = sale }
                }
                Color.clear.frame(height: 8).ckListRow()
            }
            .listStyle(.plain)
            .refreshable { await store.refresh() }
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 0)
            .scrollDismissesKeyboard(.immediately)
            .animation(.default, value: filteredSales)
            .ckDeleteAlert("Sale", item: $pendingSaleDelete,
                           name: { "the \($0.productName) sale from \(Fmt.longDate($0.date))? The \($0.quantityLabel) will go back to your stock" }) { sale in
                withAnimation { store.deleteSale(id: sale.id) }
            }
        }
    }

    private var salesTotals: some View {
        let report = SalesReport(sales: filteredSales)
        return HStack(spacing: 0) {
            total("Sales", Fmt.peso(report.revenue))
            Divider().frame(height: 28)
            total("Cost", Fmt.peso(report.cost))
            Divider().frame(height: 28)
            total("Profit", Fmt.peso(report.profit), highlight: true)
        }
        .padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 10).fill(CKColor.aqua))
    }

    private func total(_ label: String, _ value: String, highlight: Bool = false) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(highlight ? CKColor.primary : CKColor.navy)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(CKColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// Production | Sales switch at the top of Reports.
struct ReportTabPicker: View {
    @Binding var selection: ReportTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(ReportTab.allCases) { tab in
                let isSelected = tab == selection
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selection = tab }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab == .production ? "hammer" : "cart")
                            .font(.system(size: 13, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(isSelected ? Color.white : CKColor.navy)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(RoundedRectangle(cornerRadius: 9).fill(isSelected ? CKColor.primary : Color.clear))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 11).fill(CKColor.pill))
    }
}

struct ReportRowView: View {
    let record: ProductionRecord
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                CKThumbnail(record: record, size: 60)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(record.productName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(CKColor.navy)
                            .lineLimit(1)
                        CKBadge(record.productCategory)
                    }
                    Label(Fmt.longDate(record.date), systemImage: "calendar")
                        .font(.system(size: 12))
                        .foregroundStyle(CKColor.textSecondary)
                    (Text("Yield: ").foregroundColor(CKColor.textSecondary)
                     + Text(record.yieldLabel).foregroundColor(CKColor.navy).fontWeight(.semibold)
                     + Text("   •   Profit: ").foregroundColor(CKColor.textSecondary)
                     + Text(Fmt.peso(record.estimatedProfit)).foregroundColor(CKColor.primary).fontWeight(.bold))
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CKColor.navy)
            }
            .ckCard(padding: 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SaleRowView: View {
    let sale: SaleRecord
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                CKThumbnail(sale: sale, size: 60)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(sale.productName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(CKColor.navy)
                            .lineLimit(1)
                        CKBadge(sale.productCategory)
                    }
                    HStack(spacing: 8) {
                        Label(Fmt.longDate(sale.date), systemImage: "calendar")
                        Label(sale.channel.rawValue, systemImage: sale.channel.icon)
                            .lineLimit(1)
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(CKColor.textSecondary)
                    (Text("\(sale.quantityLabel) × \(Fmt.peso(sale.unitPrice))").foregroundColor(CKColor.navy)
                     + Text("   •   Profit: ").foregroundColor(CKColor.textSecondary)
                     + Text(Fmt.peso(sale.profit)).foregroundColor(CKColor.primary).fontWeight(.bold))
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Fmt.peso(sale.revenue))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(CKColor.navy)
                        .monospacedDigit()
                    Text("sales")
                        .font(.system(size: 10))
                        .foregroundStyle(CKColor.textSecondary)
                }
            }
            .ckCard(padding: 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
