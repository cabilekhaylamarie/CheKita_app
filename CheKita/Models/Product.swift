import Foundation

enum ProductCategory: String, Codable, CaseIterable, Identifiable {
    case cookies = "Cookies"
    case cakes = "Cakes"
    case pastries = "Pastries"
    case breads = "Breads"
    case desserts = "Desserts"
    case drinks = "Drinks"
    case others = "Others"

    var id: String { rawValue }

    var defaultEmoji: String {
        switch self {
        case .cookies: return "🍪"
        case .cakes: return "🎂"
        case .pastries: return "🧁"
        case .breads: return "🍞"
        case .desserts: return "🍮"
        case .drinks: return "🧋"
        case .others: return "🥐"
        }
    }
}

enum YieldMode: String, Codable, CaseIterable, Identifiable {
    case target = "Target Yield"
    case actual = "Actual Yield"

    var id: String { rawValue }
}

/// A material used in a product recipe. Name, emoji and cost are snapshotted so the
/// recipe keeps working even if the material is later removed from inventory.
struct ProductIngredient: Identifiable, Codable, Hashable {
    var id: UUID
    var materialID: UUID
    var materialName: String
    var materialEmoji: String
    var quantity: Double
    var unit: MeasurementUnit
    var costPerBaseUnit: Double

    init(id: UUID = UUID(), materialID: UUID, materialName: String, materialEmoji: String,
         quantity: Double, unit: MeasurementUnit, costPerBaseUnit: Double) {
        self.id = id
        self.materialID = materialID
        self.materialName = materialName
        self.materialEmoji = materialEmoji
        self.quantity = quantity
        self.unit = unit
        self.costPerBaseUnit = costPerBaseUnit
    }

    var cost: Double {
        CostCalculator.lineCost(quantity: quantity, unit: unit, costPerBaseUnit: costPerBaseUnit)
    }

    var quantityLabel: String { "\(Fmt.number(quantity)) \(unit.label(for: quantity))" }
}

struct Product: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var description: String
    var category: ProductCategory
    var emoji: String
    var imageFileName: String?
    var imageAssetName: String?
    /// Small JPEG thumbnail (base64) saved in Firestore so the photo also shows
    /// on other devices and after reinstalling. No Firebase Storage needed.
    var imageData: String? = nil
    var ingredients: [ProductIngredient]
    /// Labor, gas/electricity, packaging, delivery… Optional so products saved
    /// before this feature still decode.
    var overheads: [OverheadCost]? = nil
    var yieldMode: YieldMode
    var targetYield: Int
    var actualYield: Int?
    var yieldUnit: String
    var desiredProfitPercent: Double
    var stock: Int
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(),
         name: String,
         description: String = "",
         category: ProductCategory,
         emoji: String? = nil,
         imageFileName: String? = nil,
         imageAssetName: String? = nil,
         ingredients: [ProductIngredient] = [],
         overheads: [OverheadCost] = [],
         yieldMode: YieldMode = .target,
         targetYield: Int,
         actualYield: Int? = nil,
         yieldUnit: String = "pcs",
         desiredProfitPercent: Double,
         stock: Int = 0,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.emoji = emoji ?? category.defaultEmoji
        self.imageFileName = imageFileName
        self.imageAssetName = imageAssetName
        self.ingredients = ingredients
        self.overheads = overheads
        self.yieldMode = yieldMode
        self.targetYield = targetYield
        self.actualYield = actualYield
        self.yieldUnit = yieldUnit
        self.desiredProfitPercent = desiredProfitPercent
        self.stock = stock
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Yield used for costing, depending on the selected mode.
    var effectiveYield: Int {
        switch yieldMode {
        case .target: return targetYield
        case .actual: return actualYield ?? targetYield
        }
    }

    var yieldLabel: String { yieldMode == .target ? "Target Yield (pieces)" : "Actual Yield (pieces)" }

    var stockLabel: String { "\(stock) \(yieldUnit)" }

    /// Overhead lines, never nil.
    var overheadList: [OverheadCost] { overheads ?? [] }

    /// Labor and other extra costs for one batch at the current yield.
    var overheadCost: Double { overheadList.totalCost(forYield: effectiveYield) }
}
