import Foundation

/// Persistence abstraction used by `DataStore`. The app ships with `FirebaseDataRepository`
/// (Cloud Firestore, per-user documents under users/{uid}).
protocol DataRepository {
    func fetchProducts() async throws -> [Product]
    func fetchMaterials() async throws -> [Material]
    func fetchProductionRecords() async throws -> [ProductionRecord]
    func fetchSales() async throws -> [SaleRecord]

    func saveProduct(_ product: Product) async throws
    func deleteProduct(id: UUID) async throws

    func saveMaterial(_ material: Material) async throws
    func deleteMaterial(id: UUID) async throws

    func saveProductionRecord(_ record: ProductionRecord) async throws
    func deleteProductionRecord(id: UUID) async throws

    func saveSale(_ sale: SaleRecord) async throws
    func deleteSale(id: UUID) async throws

    /// Records a production atomically: saves the record, the updated product stock
    /// and any deducted materials in one write batch.
    func commitProduction(record: ProductionRecord, product: Product, materials: [Material]) async throws

    /// Records a sale atomically: saves the sale and the product's reduced stock together.
    func commitSale(sale: SaleRecord, product: Product) async throws

    /// Removes a sale and puts the quantity back into the product's stock.
    func revertSale(id: UUID, product: Product) async throws

    func saveReportSummary(_ summary: ReportSummary) async throws

    /// Whether sample data was already created for this workspace (stored on the user document).
    func isWorkspaceSeeded() async throws -> Bool
    func markWorkspaceSeeded() async throws

    /// Replaces the whole workspace (used for seeding, sample data and clear).
    func replaceAll(products: [Product], materials: [Material],
                    records: [ProductionRecord], sales: [SaleRecord]) async throws
}
