import Foundation

/// One ingredient line inside a production record (already scaled to the produced quantity).
struct ProductionLine: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var emoji: String
    var quantity: Double
    var unit: MeasurementUnit
    /// Cost of one `unit` (e.g. ₱0.060 per g).
    var unitCost: Double
    var total: Double

    init(id: UUID = UUID(), name: String, emoji: String, quantity: Double, unit: MeasurementUnit, unitCost: Double, total: Double) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.quantity = quantity
        self.unit = unit
        self.unitCost = unitCost
        self.total = total
    }

    var quantityLabel: String { "\(Fmt.number(quantity)) \(unit.label(for: quantity))" }
}

/// A batch the user actually produced. Snapshots everything needed for reports.
struct ProductionRecord: Identifiable, Codable, Hashable {
    var id: UUID
    var productID: UUID
    var productName: String
    var productCategory: ProductCategory
    var productEmoji: String
    var imageFileName: String?
    var imageAssetName: String?
    var imageData: String? = nil
    var date: Date
    var quantity: Int
    var yieldUnit: String
    var desiredProfitPercent: Double
    var lines: [ProductionLine]
    /// Labor and other extra costs for this batch (nil on records saved before the feature).
    var overheadLines: [OverheadLine]? = nil
    /// Ingredients only. nil on older records, where `totalCost` is the ingredient cost.
    var ingredientsCost: Double? = nil
    /// Ingredients + overhead.
    var totalCost: Double
    var costPerPiece: Double
    var suggestedSRP: Double
    var estimatedProfit: Double
    var notes: String
    var materialsDeducted: Bool
    var createdAt: Date

    var yieldLabel: String { "\(quantity) \(yieldUnit)" }

    var overheadList: [OverheadLine] { overheadLines ?? [] }
    var overheadCost: Double { overheadList.reduce(0) { $0 + $1.total } }
    /// Ingredient cost, falling back to the total for records saved before overheads existed.
    var ingredientCost: Double { ingredientsCost ?? (totalCost - overheadCost) }
}

/// One labor / overhead line inside a production record, already scaled to the batch.
struct OverheadLine: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var icon: String
    var basis: OverheadBasis
    var amount: Double
    var total: Double

    init(id: UUID = UUID(), name: String, icon: String = "plus.circle",
         basis: OverheadBasis = .perBatch, amount: Double, total: Double) {
        self.id = id
        self.name = name
        self.icon = icon
        self.basis = basis
        self.amount = amount
        self.total = total
    }

    var basisLabel: String { "\(Fmt.peso(amount)) / \(basis.shortLabel)" }
}
