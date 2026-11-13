import Foundation

/// How a batch was sold. Kept for the sales history and the real (not estimated) profit.
enum SaleChannel: String, Codable, CaseIterable, Identifiable {
    case walkIn = "Walk-in"
    case order = "Order"
    case online = "Online"
    case reseller = "Reseller"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .walkIn: return "figure.walk"
        case .order: return "list.clipboard"
        case .online: return "iphone"
        case .reseller: return "shippingbox"
        }
    }
}

/// An actual sale. Recording one lowers the product stock and feeds the Reports screen,
/// so CheKita can compare real income against real cost.
struct SaleRecord: Identifiable, Codable, Hashable {
    var id: UUID
    var productID: UUID
    var productName: String
    var productCategory: ProductCategory
    var productEmoji: String
    var imageFileName: String?
    var imageAssetName: String?
    var imageData: String?
    var date: Date
    var quantity: Int
    var unitLabel: String
    /// Price the customer actually paid per piece.
    var unitPrice: Double
    /// Cost per piece at the time of the sale (snapshot, so old sales stay correct).
    var unitCost: Double
    var channel: SaleChannel
    var customer: String
    var notes: String
    var createdAt: Date

    init(id: UUID = UUID(),
         productID: UUID,
         productName: String,
         productCategory: ProductCategory,
         productEmoji: String,
         imageFileName: String? = nil,
         imageAssetName: String? = nil,
         imageData: String? = nil,
         date: Date = Date(),
         quantity: Int,
         unitLabel: String = "pcs",
         unitPrice: Double,
         unitCost: Double,
         channel: SaleChannel = .walkIn,
         customer: String = "",
         notes: String = "",
         createdAt: Date = Date()) {
        self.id = id
        self.productID = productID
        self.productName = productName
        self.productCategory = productCategory
        self.productEmoji = productEmoji
        self.imageFileName = imageFileName
        self.imageAssetName = imageAssetName
        self.imageData = imageData
        self.date = date
        self.quantity = quantity
        self.unitLabel = unitLabel
        self.unitPrice = unitPrice
        self.unitCost = unitCost
        self.channel = channel
        self.customer = customer
        self.notes = notes
        self.createdAt = createdAt
    }

    /// Money received.
    var revenue: Double { unitPrice * Double(quantity) }
    /// What those pieces cost to make.
    var cost: Double { unitCost * Double(quantity) }
    /// Real profit — revenue minus cost.
    var profit: Double { revenue - cost }
    /// Profit as a percentage of cost.
    var marginPercent: Double { cost > 0 ? (profit / cost) * 100 : 0 }

    var quantityLabel: String { "\(quantity) \(unitLabel)" }
}

/// Aggregated view over sales, used by Home and Reports.
struct SalesReport {
    let sales: [SaleRecord]

    var transactions: Int { sales.count }
    var unitsSold: Int { sales.reduce(0) { $0 + $1.quantity } }
    var revenue: Double { sales.reduce(0) { $0 + $1.revenue } }
    var cost: Double { sales.reduce(0) { $0 + $1.cost } }
    var profit: Double { sales.reduce(0) { $0 + $1.profit } }

    /// Product that brought in the most money.
    var bestSeller: (name: String, revenue: Double)? {
        var totals: [String: Double] = [:]
        for sale in sales { totals[sale.productName, default: 0] += sale.revenue }
        guard let best = totals.max(by: { $0.value < $1.value }) else { return nil }
        return (best.key, best.value)
    }

    func filtered(category: String, search: String) -> [SaleRecord] {
        let query = search.trimmed
        return sales.filter { sale in
            (category == "All" || sale.productCategory.rawValue == category) &&
            (query.isEmpty || sale.productName.localizedCaseInsensitiveContains(query)
                || sale.customer.localizedCaseInsensitiveContains(query))
        }
    }

    /// Sales inside the current calendar month.
    static func thisMonth(_ sales: [SaleRecord], now: Date = Date(), calendar: Calendar = .current) -> [SaleRecord] {
        sales.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
    }
}
