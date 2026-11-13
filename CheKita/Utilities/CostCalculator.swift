import Foundation

struct CostSummary: Codable, Hashable {
    var ingredientCost: Double
    /// Labor, gas/electricity, packaging, delivery… for the whole batch.
    var overheadCost: Double
    var totalCost: Double
    var yield: Int
    var desiredProfitPercent: Double
    var costPerPiece: Double
    var suggestedSRP: Double
    var estimatedProfit: Double

    init(ingredientCost: Double, overheadCost: Double = 0, totalCost: Double, yield: Int,
         desiredProfitPercent: Double, costPerPiece: Double, suggestedSRP: Double, estimatedProfit: Double) {
        self.ingredientCost = ingredientCost
        self.overheadCost = overheadCost
        self.totalCost = totalCost
        self.yield = yield
        self.desiredProfitPercent = desiredProfitPercent
        self.costPerPiece = costPerPiece
        self.suggestedSRP = suggestedSRP
        self.estimatedProfit = estimatedProfit
    }

    static let empty = CostSummary(ingredientCost: 0, overheadCost: 0, totalCost: 0, yield: 0,
                                   desiredProfitPercent: 0, costPerPiece: 0, suggestedSRP: 0, estimatedProfit: 0)
}

/// All costing math lives here so every screen uses identical formulas.
///
/// - Line cost        = quantity × unit→base factor × cost per base unit
/// - Overhead cost    = Σ (per-batch amounts + per-piece amounts × yield)
/// - Total cost       = ingredient cost + overhead cost
/// - Cost per piece   = total cost ÷ yield
/// - Suggested SRP    = cost per piece × (1 + desired profit %)
/// - Estimated profit = (SRP − cost per piece) × yield
enum CostCalculator {
    static func lineCost(quantity: Double, unit: MeasurementUnit, costPerBaseUnit: Double) -> Double {
        guard quantity > 0, costPerBaseUnit >= 0 else { return 0 }
        return quantity * unit.toBaseFactor * costPerBaseUnit
    }

    static func summary(ingredientCost: Double, overheadCost: Double = 0, yield: Int, profitPercent: Double) -> CostSummary {
        let ingredients = max(0, ingredientCost)
        let overhead = max(0, overheadCost)
        let total = ingredients + overhead
        let pieces = max(0, yield)
        let costPerPiece = pieces > 0 ? total / Double(pieces) : 0
        let srp = costPerPiece * (1 + max(0, profitPercent) / 100)
        let profit = (srp - costPerPiece) * Double(pieces)
        return CostSummary(ingredientCost: ingredients,
                           overheadCost: overhead,
                           totalCost: total,
                           yield: pieces,
                           desiredProfitPercent: profitPercent,
                           costPerPiece: costPerPiece,
                           suggestedSRP: srp,
                           estimatedProfit: profit)
    }

    /// Profit percentage implied by a selling price the user typed in.
    ///
    ///     Revenue = selling price × yield
    ///     Profit  = revenue − total cost
    ///     Profit %= profit ÷ total cost × 100
    static func profitPercent(sellingPrice: Double, yield: Int, totalCost: Double) -> Double {
        guard totalCost > 0, yield > 0, sellingPrice > 0 else { return 0 }
        let revenue = sellingPrice * Double(yield)
        return ((revenue - totalCost) / totalCost) * 100
    }

    /// Selling price that a profit percentage works out to (used when editing an older product).
    static func sellingPrice(profitPercent: Double, yield: Int, totalCost: Double) -> Double {
        guard totalCost > 0, yield > 0 else { return 0 }
        let revenue = totalCost * (1 + max(0, profitPercent) / 100)
        return revenue / Double(yield)
    }
}
