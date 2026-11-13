import Foundation

enum ProductionRecordBuilder {
    /// Builds a production record. `ingredients` must already carry up-to-date costs.
    /// Ingredient quantities and overhead are scaled from the recipe's batch yield
    /// to the produced quantity.
    static func build(product: Product,
                      ingredients: [ProductIngredient],
                      quantity: Int,
                      date: Date,
                      notes: String,
                      materialsDeducted: Bool) -> ProductionRecord {
        let batchYield = max(product.effectiveYield, 1)
        let batches = Double(quantity) / Double(batchYield)

        let lines = ingredients.map { ingredient -> ProductionLine in
            let scaledQuantity = ingredient.quantity * batches
            let unitCost = ingredient.costPerBaseUnit * ingredient.unit.toBaseFactor
            return ProductionLine(name: ingredient.materialName,
                                  emoji: ingredient.materialEmoji,
                                  quantity: scaledQuantity,
                                  unit: ingredient.unit,
                                  unitCost: unitCost,
                                  total: scaledQuantity * unitCost)
        }

        // Per-batch costs scale with the number of batches; per-piece costs with the quantity.
        let overheadLines = product.overheadList.map { overhead -> OverheadLine in
            let total: Double
            switch overhead.basis {
            case .perBatch: total = overhead.amount * batches
            case .perPiece: total = overhead.amount * Double(quantity)
            }
            return OverheadLine(name: overhead.name,
                                icon: overhead.icon,
                                basis: overhead.basis,
                                amount: overhead.amount,
                                total: total)
        }

        let ingredientsCost = lines.reduce(0) { $0 + $1.total }
        let overheadCost = overheadLines.reduce(0) { $0 + $1.total }
        let summary = CostCalculator.summary(ingredientCost: ingredientsCost,
                                             overheadCost: overheadCost,
                                             yield: quantity,
                                             profitPercent: product.desiredProfitPercent)

        return ProductionRecord(id: UUID(),
                                productID: product.id,
                                productName: product.name,
                                productCategory: product.category,
                                productEmoji: product.emoji,
                                imageFileName: product.imageFileName,
                                imageAssetName: product.imageAssetName,
                                imageData: product.imageData,
                                date: date,
                                quantity: quantity,
                                yieldUnit: product.yieldUnit,
                                desiredProfitPercent: product.desiredProfitPercent,
                                lines: lines,
                                overheadLines: overheadLines,
                                ingredientsCost: ingredientsCost,
                                totalCost: summary.totalCost,
                                costPerPiece: summary.costPerPiece,
                                suggestedSRP: summary.suggestedSRP,
                                estimatedProfit: summary.estimatedProfit,
                                notes: notes.trimmed,
                                materialsDeducted: materialsDeducted,
                                createdAt: Date())
    }
}
