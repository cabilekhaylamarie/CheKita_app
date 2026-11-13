import Foundation

enum MaterialCategory: String, Codable, CaseIterable, Identifiable {
    case dryGoods = "Dry Goods"
    case dairy = "Dairy"
    case packaging = "Packaging"
    case others = "Others"

    var id: String { rawValue }
}

/// An ingredient or supply kept in inventory.
struct Material: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var category: MaterialCategory
    /// Unit used for both purchase price and stock.
    var unit: MeasurementUnit
    /// Price paid for `costQuantity` of `unit` (e.g. ₱120 for 500 g).
    var cost: Double
    var costQuantity: Double
    var currentStock: Double
    var notes: String
    var emoji: String
    var imageFileName: String?
    var imageAssetName: String?
    /// Small JPEG thumbnail (base64) saved in Firestore.
    var imageData: String? = nil
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(),
         name: String,
         category: MaterialCategory,
         unit: MeasurementUnit,
         cost: Double,
         costQuantity: Double = 1,
         currentStock: Double,
         notes: String = "",
         emoji: String,
         imageFileName: String? = nil,
         imageAssetName: String? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.category = category
        self.unit = unit
        self.cost = cost
        self.costQuantity = costQuantity
        self.currentStock = currentStock
        self.notes = notes
        self.emoji = emoji
        self.imageFileName = imageFileName
        self.imageAssetName = imageAssetName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Cost of one base unit (1 g, 1 ml or 1 pc).
    var costPerBaseUnit: Double {
        let base = costQuantity * unit.toBaseFactor
        return base > 0 ? cost / base : 0
    }

    /// "₱60.00 / kg" or "₱120.00 / 500 g"
    var priceLabel: String {
        if costQuantity == 1 {
            return "\(Fmt.peso(cost)) / \(unit.label(for: 1))"
        }
        return "\(Fmt.peso(cost)) / \(Fmt.number(costQuantity)) \(unit.label(for: costQuantity))"
    }

    /// "2 kg", "12 pcs"
    var stockLabel: String {
        "\(Fmt.number(currentStock)) \(unit.label(for: currentStock))"
    }
}
