import Foundation

/// Aggregated view over production records, used by Home and Reports.
struct Report {
    let records: [ProductionRecord]

    var totalProductions: Int { records.count }
    var totalUnitsProduced: Int { records.reduce(0) { $0 + $1.quantity } }
    var totalCost: Double { records.reduce(0) { $0 + $1.totalCost } }
    var totalIngredientCost: Double { records.reduce(0) { $0 + $1.ingredientCost } }
    var totalOverheadCost: Double { records.reduce(0) { $0 + $1.overheadCost } }
    var totalEstimatedProfit: Double { records.reduce(0) { $0 + $1.estimatedProfit } }

    func filtered(category: String, search: String) -> [ProductionRecord] {
        let query = search.trimmed
        return records.filter { record in
            (category == "All" || record.productCategory.rawValue == category) &&
            (query.isEmpty || record.productName.localizedCaseInsensitiveContains(query))
        }
    }
}

/// Aggregated report document stored at users/{uid}/reports/summary.
/// Recomputed from production records and sales whenever either changes.
struct ReportSummary: Codable, Hashable {
    struct CategoryTotals: Codable, Hashable {
        var productions: Int
        var unitsProduced: Int
        var totalCost: Double
        var estimatedProfit: Double
        var unitsSold: Int
        var revenue: Double
        var actualProfit: Double
    }

    // Production
    var totalProductions: Int
    var totalUnitsProduced: Int
    var totalCost: Double
    var totalIngredientCost: Double
    var totalOverheadCost: Double
    var totalEstimatedProfit: Double
    var lastProductionDate: Date?

    // Sales
    var totalSales: Int
    var totalUnitsSold: Int
    var totalRevenue: Double
    var totalCostOfSales: Double
    var totalActualProfit: Double
    var lastSaleDate: Date?
    var bestSellingProduct: String?

    var byCategory: [String: CategoryTotals]
    var updatedAt: Date

    init(records: [ProductionRecord], sales: [SaleRecord], updatedAt: Date = Date()) {
        let production = Report(records: records)
        totalProductions = production.totalProductions
        totalUnitsProduced = production.totalUnitsProduced
        totalCost = production.totalCost
        totalIngredientCost = production.totalIngredientCost
        totalOverheadCost = production.totalOverheadCost
        totalEstimatedProfit = production.totalEstimatedProfit
        lastProductionDate = records.map(\.date).max()

        let salesReport = SalesReport(sales: sales)
        totalSales = salesReport.transactions
        totalUnitsSold = salesReport.unitsSold
        totalRevenue = salesReport.revenue
        totalCostOfSales = salesReport.cost
        totalActualProfit = salesReport.profit
        lastSaleDate = sales.map(\.date).max()
        bestSellingProduct = salesReport.bestSeller?.name

        var categories: [String: CategoryTotals] = [:]
        let empty = CategoryTotals(productions: 0, unitsProduced: 0, totalCost: 0,
                                   estimatedProfit: 0, unitsSold: 0, revenue: 0, actualProfit: 0)
        for record in records {
            var entry = categories[record.productCategory.rawValue] ?? empty
            entry.productions += 1
            entry.unitsProduced += record.quantity
            entry.totalCost += record.totalCost
            entry.estimatedProfit += record.estimatedProfit
            categories[record.productCategory.rawValue] = entry
        }
        for sale in sales {
            var entry = categories[sale.productCategory.rawValue] ?? empty
            entry.unitsSold += sale.quantity
            entry.revenue += sale.revenue
            entry.actualProfit += sale.profit
            categories[sale.productCategory.rawValue] = entry
        }
        byCategory = categories
        self.updatedAt = updatedAt
    }
}
