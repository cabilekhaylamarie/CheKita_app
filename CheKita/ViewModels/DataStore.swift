import Foundation
import UIKit

/// Single source of truth for products, inventory, production records and sales.
/// Changes are applied to the UI immediately and written to Cloud Firestore.
/// Photos stay on the device, with a small thumbnail inside the Firestore document
/// (no Firebase Storage, so there is nothing to pay for).
@MainActor
final class DataStore: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var materials: [Material] = []
    @Published private(set) var records: [ProductionRecord] = []
    @Published private(set) var sales: [SaleRecord] = []
    @Published private(set) var isLoaded = false
    @Published private(set) var isRefreshing = false
    /// Set when the initial load fails (e.g. offline with no cache); the UI offers a retry.
    @Published private(set) var loadError: String?
    @Published var lastError: String?

    private var repository: DataRepository?
    private(set) var userID: String?

    // MARK: Lifecycle

    func configure(userID: String) async {
        if self.userID == userID && isLoaded && loadError == nil { return }
        self.userID = userID
        isLoaded = false
        loadError = nil
        let repo = ServiceFactory.makeRepository(userID: userID)
        repository = repo
        await load(from: repo, seedIfNeeded: true)
        isLoaded = true
    }

    /// Re-reads everything from Firestore (pull to refresh / retry).
    func refresh() async {
        guard let repository else { return }
        isRefreshing = true
        await load(from: repository, seedIfNeeded: loadError != nil)
        isRefreshing = false
        isLoaded = true
    }

    func retryLoad() async {
        guard let userID else { return }
        self.userID = nil
        await configure(userID: userID)
    }

    private func load(from repo: DataRepository, seedIfNeeded: Bool) async {
        do {
            async let productsTask = repo.fetchProducts()
            async let materialsTask = repo.fetchMaterials()
            async let recordsTask = repo.fetchProductionRecords()
            async let salesTask = repo.fetchSales()
            var fetchedProducts = try await productsTask
            var fetchedMaterials = try await materialsTask
            var fetchedRecords = try await recordsTask
            var fetchedSales = try await salesTask

            let workspaceIsEmpty = fetchedProducts.isEmpty && fetchedMaterials.isEmpty
                && fetchedRecords.isEmpty && fetchedSales.isEmpty
            var alreadySeeded = true
            if seedIfNeeded && workspaceIsEmpty {
                alreadySeeded = try await repo.isWorkspaceSeeded()
            }
            if seedIfNeeded && workspaceIsEmpty && !alreadySeeded {
                let seed = SeedData.make()
                try await repo.replaceAll(products: seed.products, materials: seed.materials,
                                          records: seed.records, sales: seed.sales)
                fetchedProducts = seed.products
                fetchedMaterials = seed.materials
                fetchedRecords = seed.records
                fetchedSales = seed.sales
            }
            if seedIfNeeded {
                try? await repo.markWorkspaceSeeded()
            }

            products = fetchedProducts.sorted { $0.createdAt > $1.createdAt }
            materials = fetchedMaterials.sorted { $0.createdAt > $1.createdAt }
            records = fetchedRecords.sorted { $0.date > $1.date }
            sales = fetchedSales.sorted { $0.date > $1.date }
            loadError = nil
        } catch {
            let message = "Couldn't load your data from the cloud. \(FirestoreErrorText.describe(error))"
            if products.isEmpty && materials.isEmpty && records.isEmpty && sales.isEmpty {
                loadError = message
            } else {
                lastError = message
            }
        }
    }

    func reset() {
        products = []
        materials = []
        records = []
        sales = []
        repository = nil
        userID = nil
        isLoaded = false
        loadError = nil
        lastError = nil
    }

    // MARK: Lookup

    func product(id: UUID) -> Product? { products.first { $0.id == id } }
    func material(id: UUID) -> Material? { materials.first { $0.id == id } }
    func record(id: UUID) -> ProductionRecord? { records.first { $0.id == id } }
    func sale(id: UUID) -> SaleRecord? { sales.first { $0.id == id } }

    var report: Report { Report(records: records) }
    var salesReport: SalesReport { SalesReport(sales: sales) }

    func records(forProduct id: UUID) -> [ProductionRecord] {
        records.filter { $0.productID == id }
    }

    func sales(forProduct id: UUID) -> [SaleRecord] {
        sales.filter { $0.productID == id }
    }

    // MARK: Costing (always resolved against current inventory prices)

    func costPerBaseUnit(for ingredient: ProductIngredient) -> Double {
        if let m = material(id: ingredient.materialID), m.unit.dimension == ingredient.unit.dimension {
            return m.costPerBaseUnit
        }
        return ingredient.costPerBaseUnit
    }

    /// Ingredient with the latest name, emoji and price from inventory.
    func resolved(_ ingredient: ProductIngredient) -> ProductIngredient {
        var copy = ingredient
        if let m = material(id: ingredient.materialID) {
            copy.materialName = m.name
            copy.materialEmoji = m.emoji
        }
        copy.costPerBaseUnit = costPerBaseUnit(for: ingredient)
        return copy
    }

    func resolvedIngredients(for product: Product) -> [ProductIngredient] {
        product.ingredients.map(resolved)
    }

    func ingredientCost(for product: Product) -> Double {
        resolvedIngredients(for: product).reduce(0) { $0 + $1.cost }
    }

    /// Labor, gas, packaging and other extra costs for one batch.
    func overheadCost(for product: Product) -> Double {
        product.overheadList.totalCost(forYield: product.effectiveYield)
    }

    func summary(for product: Product) -> CostSummary {
        CostCalculator.summary(ingredientCost: ingredientCost(for: product),
                               overheadCost: overheadCost(for: product),
                               yield: product.effectiveYield,
                               profitPercent: product.desiredProfitPercent)
    }

    // MARK: Products

    func saveProduct(_ product: Product) {
        var updated = product
        updated.updatedAt = Date()
        if let index = products.firstIndex(where: { $0.id == updated.id }) {
            products[index] = updated
        } else {
            products.insert(updated, at: 0)
        }
        persist { try await $0.saveProduct(updated) }
    }

    func deleteProduct(id: UUID) {
        guard let product = product(id: id) else { return }
        products.removeAll { $0.id == id }
        ImageStore.shared.delete(product.imageFileName)
        persist { try await $0.deleteProduct(id: id) }
    }

    // MARK: Materials

    func saveMaterial(_ material: Material) {
        var updated = material
        updated.updatedAt = Date()
        if let index = materials.firstIndex(where: { $0.id == updated.id }) {
            materials[index] = updated
        } else {
            materials.insert(updated, at: 0)
        }
        persist { try await $0.saveMaterial(updated) }
    }

    func updateStock(materialID: UUID, newStock: Double) {
        guard var m = material(id: materialID) else { return }
        m.currentStock = max(0, newStock)
        saveMaterial(m)
    }

    func productsUsing(materialID: UUID) -> [Product] {
        products.filter { $0.ingredients.contains { $0.materialID == materialID } }
    }

    func deleteMaterial(id: UUID) {
        guard let m = material(id: id) else { return }
        // Freeze latest name/price into recipes so their costing stays correct.
        for var product in productsUsing(materialID: id) {
            product.ingredients = product.ingredients.map { ingredient in
                guard ingredient.materialID == id else { return ingredient }
                var copy = ingredient
                copy.materialName = m.name
                copy.materialEmoji = m.emoji
                if m.unit.dimension == ingredient.unit.dimension { copy.costPerBaseUnit = m.costPerBaseUnit }
                return copy
            }
            saveProduct(product)
        }
        materials.removeAll { $0.id == id }
        ImageStore.shared.delete(m.imageFileName)
        persist { try await $0.deleteMaterial(id: id) }
    }

    // MARK: Production

    /// Materials needed for `quantity` pieces, expressed in each material's own unit.
    func materialUsage(for product: Product, quantity: Int) -> [(material: Material, amount: Double)] {
        let batches = Double(quantity) / Double(max(product.effectiveYield, 1))
        var totals: [UUID: Double] = [:]
        for ingredient in product.ingredients {
            guard let m = material(id: ingredient.materialID), m.unit.dimension == ingredient.unit.dimension else { continue }
            let baseAmount = ingredient.quantity * ingredient.unit.toBaseFactor * batches
            totals[m.id, default: 0] += baseAmount / m.unit.toBaseFactor
        }
        return totals.compactMap { id, amount in
            guard let m = material(id: id) else { return nil }
            return (m, amount)
        }
        .sorted { $0.material.name < $1.material.name }
    }

    func shortages(for product: Product, quantity: Int) -> [String] {
        materialUsage(for: product, quantity: quantity)
            .filter { $0.amount > $0.material.currentStock + 0.0001 }
            .map { "\($0.material.name): needs \(Fmt.number($0.amount)) \($0.material.unit.label(for: $0.amount)), has \($0.material.stockLabel)" }
    }

    /// Cost of producing `quantity` pieces, including labor and other costs.
    func productionCost(for product: Product, quantity: Int) -> CostSummary {
        let batchYield = max(product.effectiveYield, 1)
        let batches = Double(quantity) / Double(batchYield)
        var overhead: Double = 0
        for item in product.overheadList {
            switch item.basis {
            case .perBatch: overhead += item.amount * batches
            case .perPiece: overhead += item.amount * Double(quantity)
            }
        }
        return CostCalculator.summary(ingredientCost: ingredientCost(for: product) * batches,
                                      overheadCost: overhead,
                                      yield: quantity,
                                      profitPercent: product.desiredProfitPercent)
    }

    /// Saves the record, increases product stock and (optionally) deducts ingredients —
    /// all in one Firestore batch — then refreshes the report summary.
    @discardableResult
    func recordProduction(productID: UUID, quantity: Int, date: Date, notes: String, deductMaterials: Bool) -> ProductionRecord? {
        guard quantity > 0, let index = products.firstIndex(where: { $0.id == productID }) else { return nil }
        var product = products[index]

        let record = ProductionRecordBuilder.build(product: product,
                                                   ingredients: resolvedIngredients(for: product),
                                                   quantity: quantity,
                                                   date: date,
                                                   notes: notes,
                                                   materialsDeducted: deductMaterials)

        var changedMaterials: [Material] = []
        if deductMaterials {
            for usage in materialUsage(for: product, quantity: quantity) {
                guard let materialIndex = materials.firstIndex(where: { $0.id == usage.material.id }) else { continue }
                var material = materials[materialIndex]
                material.currentStock = max(0, material.currentStock - usage.amount)
                material.updatedAt = Date()
                materials[materialIndex] = material
                changedMaterials.append(material)
            }
        }

        product.stock += quantity
        product.updatedAt = Date()
        products[index] = product

        records.append(record)
        records.sort { $0.date > $1.date }

        let savedProduct = product
        let savedMaterials = changedMaterials
        persist { try await $0.commitProduction(record: record, product: savedProduct, materials: savedMaterials) }
        persistReportSummary()
        return record
    }

    func deleteRecord(id: UUID) {
        records.removeAll { $0.id == id }
        persist { try await $0.deleteProductionRecord(id: id) }
        persistReportSummary()
    }

    // MARK: Sales

    /// Cost of one piece right now (ingredients + labor and other costs ÷ yield).
    func costPerPiece(for product: Product) -> Double {
        summary(for: product).costPerPiece
    }

    /// Price suggested on the product, used as the default selling price.
    func suggestedPrice(for product: Product) -> Double {
        summary(for: product).suggestedSRP
    }

    /// Saves the sale and lowers the product's stock in one Firestore batch.
    @discardableResult
    func recordSale(productID: UUID,
                    quantity: Int,
                    unitPrice: Double,
                    date: Date,
                    channel: SaleChannel,
                    customer: String,
                    notes: String) -> SaleRecord? {
        guard quantity > 0, unitPrice >= 0,
              let index = products.firstIndex(where: { $0.id == productID }) else { return nil }
        var product = products[index]

        let sale = SaleRecord(productID: product.id,
                              productName: product.name,
                              productCategory: product.category,
                              productEmoji: product.emoji,
                              imageFileName: product.imageFileName,
                              imageAssetName: product.imageAssetName,
                              imageData: product.imageData,
                              date: date,
                              quantity: quantity,
                              unitLabel: product.yieldUnit,
                              unitPrice: unitPrice,
                              unitCost: costPerPiece(for: product),
                              channel: channel,
                              customer: customer.trimmed,
                              notes: notes.trimmed)

        product.stock = max(0, product.stock - quantity)
        product.updatedAt = Date()
        products[index] = product

        sales.append(sale)
        sales.sort { $0.date > $1.date }

        let savedProduct = product
        persist { try await $0.commitSale(sale: sale, product: savedProduct) }
        persistReportSummary()
        return sale
    }

    /// Deleting a sale puts the pieces back into stock, since it was recorded by mistake.
    func deleteSale(id: UUID) {
        guard let removed = sales.first(where: { $0.id == id }) else { return }
        sales.removeAll { $0.id == id }

        if let index = products.firstIndex(where: { $0.id == removed.productID }) {
            var product = products[index]
            product.stock += removed.quantity
            product.updatedAt = Date()
            products[index] = product
            let savedProduct = product
            persist { try await $0.revertSale(id: id, product: savedProduct) }
        } else {
            persist { try await $0.deleteSale(id: id) }
        }
        persistReportSummary()
    }

    private func persistReportSummary() {
        let summary = ReportSummary(records: records, sales: sales)
        persist { try await $0.saveReportSummary(summary) }
    }

    // MARK: Workspace maintenance

    func loadSampleData() {
        let seed = SeedData.make()
        products = seed.products
        materials = seed.materials
        records = seed.records.sorted { $0.date > $1.date }
        sales = seed.sales.sorted { $0.date > $1.date }
        persist { try await $0.replaceAll(products: seed.products, materials: seed.materials,
                                          records: seed.records, sales: seed.sales) }
    }

    func clearAllData() {
        products.forEach { ImageStore.shared.delete($0.imageFileName) }
        materials.forEach { ImageStore.shared.delete($0.imageFileName) }
        products = []
        materials = []
        records = []
        sales = []
        persist { try await $0.replaceAll(products: [], materials: [], records: [], sales: []) }
    }

    // MARK: Persistence

    private func persist(_ operation: @escaping (DataRepository) async throws -> Void) {
        guard let repository else { return }
        Task { [weak self] in
            do {
                try await operation(repository)
            } catch {
                guard let self else { return }
                self.lastError = "Couldn't save your changes to the cloud. \(FirestoreErrorText.describe(error))"
                // Re-sync so the screen shows what is actually stored.
                await self.refresh()
            }
        }
    }
}

/// Human-friendly descriptions for Firestore / network errors.
enum FirestoreErrorText {
    static func describe(_ error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == "FIRFirestoreErrorDomain" {
            switch nsError.code {
            case 7: return "You don't have permission to access this data. Check the Firestore security rules."
            case 14: return "The service is unavailable. Check your internet connection."
            case 16: return "Your session expired. Please log in again."
            default: break
            }
        }
        if nsError.domain == NSURLErrorDomain {
            return "Check your internet connection and try again."
        }
        return error.localizedDescription
    }
}
