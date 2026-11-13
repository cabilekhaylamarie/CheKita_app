import SwiftUI

@MainActor
final class MaterialFormViewModel: ObservableObject {
    let store: DataStore
    let editingID: UUID?
    private var original: Material?

    @Published var name = "" { didSet { nameError = nil } }
    @Published var category: MaterialCategory? { didSet { categoryError = nil } }
    @Published var unit: MeasurementUnit? { didSet { unitError = nil } }
    @Published var costText = "" { didSet { costError = nil } }
    @Published var costQuantityText = "1" { didSet { costError = nil } }
    @Published var stockText = "" { didSet { stockError = nil } }
    @Published var notes = ""
    @Published var newImageData: Data?
    @Published var existingImageFileName: String?
    @Published var existingImageAssetName: String?
    @Published var existingImageData: String?
    /// True after the user taps remove on the photo (without picking a new one).
    private var userRemovedImage = false

    @Published var nameError: String?
    @Published var categoryError: String?
    @Published var unitError: String?
    @Published var costError: String?
    @Published var stockError: String?

    init(store: DataStore, editingID: UUID?) {
        self.store = store
        self.editingID = editingID
        guard let id = editingID, let material = store.material(id: id) else { return }
        original = material
        name = material.name
        category = material.category
        unit = material.unit
        costText = Fmt.number(material.cost)
        costQuantityText = Fmt.number(material.costQuantity)
        stockText = Fmt.number(material.currentStock)
        notes = material.notes
        existingImageFileName = material.imageFileName
        existingImageAssetName = material.imageAssetName
        existingImageData = material.imageData
    }

    var isEditing: Bool { editingID != nil }
    var title: String { isEditing ? "Edit Material" : "Add Material" }
    var usedInProductsCount: Int {
        guard let editingID else { return 0 }
        return store.productsUsing(materialID: editingID).count
    }

    var previewImage: UIImage? {
        if let data = newImageData { return UIImage(data: data) }
        if let image = ImageStore.shared.image(named: existingImageFileName) { return image }
        if let image = ImageStore.shared.image(base64: existingImageData, cacheKey: editingID.map { "m-form-\($0)" }) { return image }
        if let asset = existingImageAssetName { return UIImage(named: asset) }
        return nil
    }

    func removeImage() {
        newImageData = nil
        existingImageFileName = nil
        existingImageAssetName = nil
        existingImageData = nil
        userRemovedImage = true
    }

    func save() -> Bool {
        Keyboard.dismiss()
        nameError = name.trimmed.isEmpty ? "Material name is required." : nil
        if nameError == nil,
           store.materials.contains(where: { $0.id != editingID && $0.name.caseInsensitiveCompare(name.trimmed) == .orderedSame }) {
            nameError = "A material with this name already exists."
        }
        categoryError = category == nil ? "Please select a category." : nil
        unitError = unit == nil ? "Please select a unit." : nil

        let cost = Fmt.parse(costText)
        let costQuantity = Fmt.parse(costQuantityText)
        if cost == nil {
            costError = costText.trimmed.isEmpty ? "Cost is required." : "Cost must be a valid number."
        } else if let cost, cost < 0 {
            costError = "Cost can't be negative."
        } else if costQuantity == nil || (costQuantity ?? 0) <= 0 {
            costError = "Enter the quantity this price covers (e.g. 1 or 500)."
        }

        let stock = Fmt.parse(stockText)
        if stock == nil {
            stockError = stockText.trimmed.isEmpty ? "Current stock is required. Enter 0 if you have none." : "Stock must be a valid number."
        } else if let stock, stock < 0 {
            stockError = "Stock can't be negative."
        }

        guard nameError == nil, categoryError == nil, unitError == nil, costError == nil, stockError == nil,
              let category, let unit, let cost, let costQuantity, let stock else { return false }

        var material = original.flatMap { store.material(id: $0.id) } ?? original ?? Material(name: name.trimmed, category: category, unit: unit, cost: cost,
                                            currentStock: stock, emoji: EmojiGuesser.material(name: name, category: category))
        if let data = newImageData, let fileName = ImageStore.shared.save(data) {
            ImageStore.shared.delete(material.imageFileName)
            material.imageFileName = fileName
            material.imageAssetName = nil
            // Small copy for Firestore so the photo shows on other devices too.
            material.imageData = ImageStore.shared.thumbnailBase64(from: data, maxDimension: 500)
        } else if userRemovedImage {
            ImageStore.shared.delete(material.imageFileName)
            material.imageFileName = nil
            material.imageAssetName = nil
            material.imageData = nil
        }

        if original == nil || original?.name != name.trimmed || original?.category != category {
            material.emoji = EmojiGuesser.material(name: name, category: category)
        }
        material.name = name.trimmed
        material.category = category
        material.unit = unit
        material.cost = cost
        material.costQuantity = costQuantity
        material.currentStock = stock
        material.notes = notes.trimmed
        store.saveMaterial(material)
        return true
    }
}
