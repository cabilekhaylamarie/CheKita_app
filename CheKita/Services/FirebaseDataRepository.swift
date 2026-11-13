import Foundation
import FirebaseFirestore

/// Cloud Firestore persistence. Every document lives under the signed-in user's UID:
///
///     users/{uid}                              profile (see FirebaseAuthService) + `workspaceSeeded`
///     users/{uid}/products/{productID}         product incl. `ingredients` and `overheads` arrays
///     users/{uid}/materials/{materialID}       inventory item
///     users/{uid}/productionRecords/{id}       recorded batch with scaled ingredient + overhead lines
///     users/{uid}/sales/{saleID}               recorded sale (quantity, price, real profit)
///     users/{uid}/reports/summary              aggregated totals for production and sales
///
/// Photos are NOT stored in Firebase Storage: a small base64 thumbnail travels inside the
/// document itself (`imageData`), which keeps the app on Firebase's free tier.
///
/// Security rules (firebase/firestore.rules) only allow a user to read/write their own subtree.
final class FirebaseDataRepository: DataRepository {
    private let db: Firestore
    private let userDocument: DocumentReference

    private enum Collection {
        static let products = "products"
        static let materials = "materials"
        static let records = "productionRecords"
        static let sales = "sales"
        static let reports = "reports"
    }

    /// Firestore allows 500 writes per batch; stay safely below.
    private let batchLimit = 450
    private let encoder = Firestore.Encoder()

    init(userID: String) {
        db = Firestore.firestore()
        userDocument = db.collection("users").document(userID)
    }

    // MARK: Reads

    func fetchProducts() async throws -> [Product] { try await fetch(Collection.products) }
    func fetchMaterials() async throws -> [Material] { try await fetch(Collection.materials) }
    func fetchProductionRecords() async throws -> [ProductionRecord] { try await fetch(Collection.records) }
    func fetchSales() async throws -> [SaleRecord] { try await fetch(Collection.sales) }

    private func fetch<T: Decodable>(_ name: String) async throws -> [T] {
        let snapshot = try await userDocument.collection(name).getDocuments()
        return snapshot.documents.compactMap { document in
            do {
                return try document.data(as: T.self)
            } catch {
                #if DEBUG
                print("CheKita Firestore: skipped \(name)/\(document.documentID): \(error)")
                #endif
                return nil
            }
        }
    }

    // MARK: Writes

    func saveProduct(_ product: Product) async throws {
        try await reference(Collection.products, product.id).setData(encode(product))
    }

    func deleteProduct(id: UUID) async throws {
        try await reference(Collection.products, id).delete()
    }

    func saveMaterial(_ material: Material) async throws {
        try await reference(Collection.materials, material.id).setData(encode(material))
    }

    func deleteMaterial(id: UUID) async throws {
        try await reference(Collection.materials, id).delete()
    }

    func saveProductionRecord(_ record: ProductionRecord) async throws {
        try await reference(Collection.records, record.id).setData(encode(record))
    }

    func deleteProductionRecord(id: UUID) async throws {
        try await reference(Collection.records, id).delete()
    }

    func saveSale(_ sale: SaleRecord) async throws {
        try await reference(Collection.sales, sale.id).setData(encode(sale))
    }

    func deleteSale(id: UUID) async throws {
        try await reference(Collection.sales, id).delete()
    }

    func commitProduction(record: ProductionRecord, product: Product, materials: [Material]) async throws {
        let batch = db.batch()
        batch.setData(try encode(record), forDocument: reference(Collection.records, record.id))
        batch.setData(try encode(product), forDocument: reference(Collection.products, product.id))
        for material in materials {
            batch.setData(try encode(material), forDocument: reference(Collection.materials, material.id))
        }
        try await batch.commit()
    }

    func commitSale(sale: SaleRecord, product: Product) async throws {
        let batch = db.batch()
        batch.setData(try encode(sale), forDocument: reference(Collection.sales, sale.id))
        batch.setData(try encode(product), forDocument: reference(Collection.products, product.id))
        try await batch.commit()
    }

    func revertSale(id: UUID, product: Product) async throws {
        let batch = db.batch()
        batch.deleteDocument(reference(Collection.sales, id))
        batch.setData(try encode(product), forDocument: reference(Collection.products, product.id))
        try await batch.commit()
    }

    func saveReportSummary(_ summary: ReportSummary) async throws {
        try await userDocument.collection(Collection.reports).document("summary").setData(encode(summary))
    }

    func isWorkspaceSeeded() async throws -> Bool {
        let snapshot = try await userDocument.getDocument()
        return snapshot.data()?["workspaceSeeded"] as? Bool ?? false
    }

    func markWorkspaceSeeded() async throws {
        try await userDocument.setData(["workspaceSeeded": true], merge: true)
    }

    func replaceAll(products: [Product], materials: [Material],
                    records: [ProductionRecord], sales: [SaleRecord]) async throws {
        var operations: [(WriteBatch) throws -> Void] = []

        for name in [Collection.products, Collection.materials, Collection.records, Collection.sales] {
            let existing = try await userDocument.collection(name).getDocuments()
            for document in existing.documents {
                let ref = document.reference
                operations.append { $0.deleteDocument(ref) }
            }
        }
        for product in products {
            let ref = reference(Collection.products, product.id)
            operations.append { [self] in $0.setData(try encode(product), forDocument: ref) }
        }
        for material in materials {
            let ref = reference(Collection.materials, material.id)
            operations.append { [self] in $0.setData(try encode(material), forDocument: ref) }
        }
        for record in records {
            let ref = reference(Collection.records, record.id)
            operations.append { [self] in $0.setData(try encode(record), forDocument: ref) }
        }
        for sale in sales {
            let ref = reference(Collection.sales, sale.id)
            operations.append { [self] in $0.setData(try encode(sale), forDocument: ref) }
        }
        let summary = ReportSummary(records: records, sales: sales)
        let summaryRef = userDocument.collection(Collection.reports).document("summary")
        operations.append { [self] in $0.setData(try encode(summary), forDocument: summaryRef) }

        var start = 0
        while start < operations.count {
            let end = min(start + batchLimit, operations.count)
            let batch = db.batch()
            for operation in operations[start..<end] {
                try operation(batch)
            }
            try await batch.commit()
            start = end
        }
    }

    // MARK: Helpers

    /// Encodes with Firestore's encoder (Dates become Timestamps, UUIDs strings).
    private func encode<T: Encodable>(_ value: T) throws -> [String: Any] {
        try encoder.encode(value)
    }

    private func reference(_ collection: String, _ id: UUID) -> DocumentReference {
        userDocument.collection(collection).document(id.uuidString)
    }
}
