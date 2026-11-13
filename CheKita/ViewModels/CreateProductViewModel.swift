import SwiftUI

struct IngredientSelection: Hashable {
    var isSelected: Bool
    var quantityText: String
    var unit: MeasurementUnit
}

/// One editable "other cost" row (labor, gas, packaging, delivery…).
struct OverheadDraft: Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var amountText: String
    var basis: OverheadBasis
    var icon: String

    init(id: UUID = UUID(), name: String, amountText: String = "", basis: OverheadBasis = .perBatch, icon: String = "plus.circle") {
        self.id = id
        self.name = name
        self.amountText = amountText
        self.basis = basis
        self.icon = icon
    }

    init(_ overhead: OverheadCost) {
        self.init(id: overhead.id,
                  name: overhead.name,
                  amountText: overhead.amount > 0 ? Fmt.number(overhead.amount) : "",
                  basis: overhead.basis,
                  icon: overhead.icon)
    }

    var amount: Double { Fmt.parse(amountText) ?? 0 }

    /// Finished line, or nil while the row is still empty/invalid.
    var overhead: OverheadCost? {
        let trimmedName = name.trimmed
        guard !trimmedName.isEmpty, let value = Fmt.parse(amountText), value > 0 else { return nil }
        return OverheadCost(id: id, name: trimmedName, amount: value, basis: basis, icon: icon)
    }
}

/// Drives the 4-step Create / Edit Product flow.
@MainActor
final class CreateProductViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case details = 1, ingredients, profit, review
    }

    let store: DataStore
    let editingProductID: UUID?
    var isEditing: Bool { editingProductID != nil }
    private var original: Product?

    @Published var step: Step = .details

    // MARK: Step 1 – Product details

    @Published var name = "" { didSet { nameError = nil } }
    @Published var productDescription = ""
    @Published var category: ProductCategory? { didSet { categoryError = nil } }
    @Published var newImageData: Data?
    @Published var existingImageFileName: String?
    @Published var existingImageAssetName: String?
    /// base64 thumbnail already saved on the product.
    @Published var existingImageData: String?
    /// True once the user taps remove on the photo without picking a new one.
    private var userRemovedImage = false

    // MARK: Step 2 – Ingredients

    @Published var selections: [UUID: IngredientSelection] = [:] {
        didSet { calculated = nil; ingredientError = nil }
    }
    @Published var ingredientSearch = ""
    @Published var showIngredientValidation = false
    /// Recipe lines whose material was removed from inventory (kept when editing).
    @Published private(set) var orphanIngredients: [ProductIngredient] = []

    // MARK: Step 3 – Labor, other costs and selling price

    @Published var overheadDrafts: [OverheadDraft] = [] {
        didSet { calculated = nil; overheadError = nil }
    }
    @Published var yieldMode: YieldMode = .target { didSet { calculated = nil; yieldError = nil } }
    @Published var targetYieldText = "" { didSet { calculated = nil; yieldError = nil } }
    @Published var actualYieldText = "" { didSet { calculated = nil; yieldError = nil } }
    @Published var yieldUnit = "pcs" { didSet { calculated = nil } }
    /// Price the user plans to sell one piece for; the profit % is derived from it.
    @Published var sellingPriceText = "" { didSet { calculated = nil; sellingPriceError = nil } }
    @Published private(set) var calculated: CostSummary?

    // MARK: Validation

    @Published var nameError: String?
    @Published var categoryError: String?
    @Published var ingredientError: String?
    @Published var overheadError: String?
    @Published var yieldError: String?
    @Published var sellingPriceError: String?

    // MARK: Completion

    @Published var showSuccess = false
    @Published private(set) var savedProductName = ""
    @Published private(set) var savedProductID: UUID?

    static let yieldUnits = ["pcs", "cups", "slices", "boxes", "packs", "bottles", "trays"]

    // MARK: Init

    init(store: DataStore, editingProductID: UUID?) {
        self.store = store
        self.editingProductID = editingProductID

        guard let id = editingProductID, let product = store.product(id: id) else { return }
        original = product

        // Product details
        name = product.name
        productDescription = product.description
        category = product.category
        existingImageFileName = product.imageFileName
        existingImageAssetName = product.imageAssetName
        existingImageData = product.imageData

        // Ingredients
        var initialSelections: [UUID: IngredientSelection] = [:]
        var orphans: [ProductIngredient] = []
        for ingredient in product.ingredients {
            if store.material(id: ingredient.materialID) != nil {
                initialSelections[ingredient.materialID] = IngredientSelection(
                    isSelected: true, quantityText: Fmt.number(ingredient.quantity), unit: ingredient.unit)
            } else {
                orphans.append(ingredient)
            }
        }
        selections = initialSelections
        orphanIngredients = orphans

        // Labor and other costs
        overheadDrafts = product.overheadList.map(OverheadDraft.init)

        // Yield and price
        yieldMode = product.yieldMode
        targetYieldText = String(product.targetYield)
        actualYieldText = product.actualYield.map(String.init) ?? ""
        yieldUnit = product.yieldUnit

        // The product stores a profit %, so turn it back into the selling price.
        let savedYield = max(product.effectiveYield, 1)
        let savedTotal = totalIngredientCost + overheadCost(forYield: savedYield)
        let price = CostCalculator.sellingPrice(profitPercent: product.desiredProfitPercent,
                                                yield: savedYield,
                                                totalCost: savedTotal)
        sellingPriceText = price > 0 ? String(format: "%.2f", price) : ""
        calculated = computeSummary()
    }

    var title: String { isEditing ? "Edit Product" : "Create Product" }
    var subtitle: String { isEditing ? "Update your food product details." : "Add a new food product to your list." }

    // MARK: Image

    var previewImage: UIImage? {
        if let data = newImageData { return UIImage(data: data) }
        if let image = ImageStore.shared.image(named: existingImageFileName) { return image }
        if let image = ImageStore.shared.image(base64: existingImageData,
                                               cacheKey: editingProductID.map { "p-form-\($0)" }) { return image }
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

    // MARK: Ingredients

    var filteredMaterials: [Material] {
        let query = ingredientSearch.trimmed
        guard !query.isEmpty else { return store.materials }
        return store.materials.filter {
            $0.name.localizedCaseInsensitiveContains(query) || $0.category.rawValue.localizedCaseInsensitiveContains(query)
        }
    }

    func selection(for material: Material) -> IngredientSelection {
        selections[material.id] ?? IngredientSelection(isSelected: false, quantityText: "", unit: material.unit.defaultRecipeUnit)
    }

    func updateSelection(_ selection: IngredientSelection, for material: Material) {
        var updated = selection
        // Typing a quantity selects the ingredient automatically.
        let previous = self.selection(for: material)
        if previous.quantityText.isEmpty && !updated.quantityText.trimmed.isEmpty && !previous.isSelected {
            updated.isSelected = true
        }
        selections[material.id] = updated
    }

    func toggle(_ material: Material) {
        var current = selection(for: material)
        current.isSelected.toggle()
        selections[material.id] = current
    }

    func hasInvalidQuantity(_ material: Material) -> Bool {
        let current = selection(for: material)
        guard current.isSelected else { return false }
        guard let quantity = Fmt.parse(current.quantityText) else { return true }
        return quantity <= 0
    }

    func lineCost(for material: Material) -> Double {
        let current = selection(for: material)
        guard current.isSelected, let quantity = Fmt.parse(current.quantityText), quantity > 0,
              current.unit.dimension == material.unit.dimension else { return 0 }
        return CostCalculator.lineCost(quantity: quantity, unit: current.unit, costPerBaseUnit: material.costPerBaseUnit)
    }

    /// Valid selected ingredients, in inventory order, with current prices.
    var builtIngredients: [ProductIngredient] {
        let fromInventory: [ProductIngredient] = store.materials.compactMap { material in
            let current = selection(for: material)
            guard current.isSelected, let quantity = Fmt.parse(current.quantityText), quantity > 0 else { return nil }
            return ProductIngredient(materialID: material.id,
                                     materialName: material.name,
                                     materialEmoji: material.emoji,
                                     quantity: quantity,
                                     unit: current.unit,
                                     costPerBaseUnit: material.costPerBaseUnit)
        }
        return fromInventory + orphanIngredients
    }

    var totalIngredientCost: Double {
        builtIngredients.reduce(0) { $0 + $1.cost }
    }

    // MARK: Labor and other costs

    /// Finished overhead lines (rows that are still empty are ignored).
    var builtOverheads: [OverheadCost] {
        overheadDrafts.compactMap(\.overhead)
    }

    func overheadCost(forYield yield: Int) -> Double {
        builtOverheads.totalCost(forYield: yield)
    }

    /// Labor and other costs at the yield currently typed in.
    var totalOverheadCost: Double {
        overheadCost(forYield: Fmt.parseInt(activeYieldText) ?? 0)
    }

    /// Ingredients + labor and other costs.
    var totalCost: Double { totalIngredientCost + totalOverheadCost }

    func addOverhead(_ preset: OverheadCost.Preset) {
        overheadDrafts.append(OverheadDraft(name: preset.name, basis: preset.basis, icon: preset.icon))
    }

    func removeOverhead(_ draft: OverheadDraft) {
        overheadDrafts.removeAll { $0.id == draft.id }
    }

    func binding(for draft: OverheadDraft) -> Binding<OverheadDraft> {
        Binding(
            get: { self.overheadDrafts.first { $0.id == draft.id } ?? draft },
            set: { updated in
                guard let index = self.overheadDrafts.firstIndex(where: { $0.id == updated.id }) else { return }
                self.overheadDrafts[index] = updated
            }
        )
    }

    // MARK: Yield and selling price

    var activeYieldText: String {
        get { yieldMode == .target ? targetYieldText : actualYieldText }
        set {
            if yieldMode == .target { targetYieldText = newValue } else { actualYieldText = newValue }
        }
    }

    var sellingPrice: Double? {
        guard let value = Fmt.parse(sellingPriceText), value > 0 else { return nil }
        return value
    }

    /// Profit percentage the typed selling price works out to.
    ///
    ///     Revenue = selling price × yield
    ///     Profit  = revenue − total cost (ingredients + labor and other costs)
    ///     Profit %= profit ÷ total cost × 100
    var profitPercent: Double {
        guard let yield = Fmt.parseInt(activeYieldText), yield > 0, let price = sellingPrice else { return 0 }
        return CostCalculator.profitPercent(sellingPrice: price, yield: yield,
                                            totalCost: totalIngredientCost + overheadCost(forYield: yield))
    }

    private func computeSummary() -> CostSummary? {
        guard let yield = Fmt.parseInt(activeYieldText), yield > 0,
              let price = sellingPrice, totalIngredientCost + overheadCost(forYield: yield) > 0 else { return nil }
        let overhead = overheadCost(forYield: yield)
        let percent = CostCalculator.profitPercent(sellingPrice: price, yield: yield,
                                                   totalCost: totalIngredientCost + overhead)
        return CostCalculator.summary(ingredientCost: totalIngredientCost,
                                      overheadCost: overhead,
                                      yield: yield,
                                      profitPercent: percent)
    }

    // MARK: Calculate

    @discardableResult
    func calculate() -> Bool {
        var valid = true

        // Yield
        if let value = Fmt.parse(activeYieldText) {
            if value <= 0 || value != value.rounded() {
                yieldError = "Enter a whole number greater than 0."
                valid = false
            } else {
                yieldError = nil
            }
        } else {
            yieldError = activeYieldText.trimmed.isEmpty ? "Yield is required." : "Yield must be a number."
            valid = false
        }

        // Labor and other costs
        if let bad = overheadDrafts.first(where: { draft in
            let hasName = !draft.name.trimmed.isEmpty
            let value = Fmt.parse(draft.amountText)
            let hasAmount = !draft.amountText.trimmed.isEmpty
            if !hasName && !hasAmount { return false }          // empty row, ignored
            if !hasName { return true }
            if !hasAmount { return true }
            return value == nil || (value ?? 0) < 0
        }) {
            overheadError = bad.name.trimmed.isEmpty
                ? "Give each extra cost a name, or remove the empty row."
                : "Enter a valid amount for \(bad.name.trimmed)."
            valid = false
        } else {
            overheadError = nil
        }

        // Selling price
        if let price = Fmt.parse(sellingPriceText) {
            if price <= 0 {
                sellingPriceError = "Enter a selling price greater than ₱0."
                valid = false
            } else {
                sellingPriceError = nil
            }
        } else {
            sellingPriceError = sellingPriceText.trimmed.isEmpty
                ? "Selling price is required."
                : "Selling price must be a valid number."
            valid = false
        }

        // Ingredients
        if builtIngredients.isEmpty {
            ingredientError = "Add at least one ingredient before calculating."
            valid = false
        } else {
            ingredientError = nil
        }

        guard valid else {
            calculated = nil
            return false
        }
        calculated = computeSummary()
        return calculated != nil
    }

    // MARK: Validation

    @discardableResult
    func validateDetails() -> Bool {
        nameError = name.trimmed.isEmpty ? "Product name is required." : nil
        if nameError == nil, name.trimmed.count > 60 { nameError = "Keep the name under 60 characters." }
        categoryError = category == nil ? "Please select a category." : nil
        return nameError == nil && categoryError == nil
    }

    @discardableResult
    func validateIngredients() -> Bool {
        showIngredientValidation = true
        let selected = store.materials.filter { selection(for: $0).isSelected }
        if selected.isEmpty && orphanIngredients.isEmpty {
            ingredientError = store.materials.isEmpty
                ? "Add materials to your inventory first."
                : "Select at least one ingredient."
            return false
        }
        if selected.contains(where: hasInvalidQuantity) {
            ingredientError = "Enter a valid quantity for each selected ingredient."
            return false
        }
        ingredientError = nil
        return true
    }

    // MARK: Navigation

    func goNext() {
        Keyboard.dismiss()
        switch step {
        case .details:
            if validateDetails() { step = .ingredients }
        case .ingredients:
            if validateIngredients() { step = .profit }
        case .profit:
            if calculated != nil || calculate() { step = .review }
        case .review:
            save()
        }
    }

    /// Returns false when already on the first step.
    func goBack() -> Bool {
        Keyboard.dismiss()
        guard let previous = Step(rawValue: step.rawValue - 1) else { return false }
        step = previous
        return true
    }

    var hasUnsavedInput: Bool {
        if isEditing { return true }
        return !name.trimmed.isEmpty || !productDescription.trimmed.isEmpty || category != nil
            || newImageData != nil || selections.values.contains { $0.isSelected }
    }

    // MARK: Save

    func save() {
        guard validateDetails() else { step = .details; return }
        guard validateIngredients() else { step = .ingredients; return }
        guard calculate(), let category, let summary = calculated else { step = .profit; return }

        // Start from the latest stored version so nothing saved meanwhile is lost.
        var product = original.flatMap { store.product(id: $0.id) } ?? original
            ?? Product(name: name.trimmed, category: category, targetYield: 1, desiredProfitPercent: 0)

        // Photo: full size on this device, small thumbnail inside the Firestore document.
        if let data = newImageData, let fileName = ImageStore.shared.save(data) {
            if product.imageFileName != fileName { ImageStore.shared.delete(product.imageFileName) }
            product.imageFileName = fileName
            product.imageAssetName = nil
            product.imageData = ImageStore.shared.thumbnailBase64(from: data)
        } else if userRemovedImage {
            ImageStore.shared.delete(product.imageFileName)
            product.imageFileName = nil
            product.imageAssetName = nil
            product.imageData = nil
        }

        let yieldValue = Fmt.parseInt(activeYieldText) ?? 1
        product.name = name.trimmed
        product.description = productDescription.trimmed
        if original == nil || original?.category != category || original?.name != name.trimmed {
            product.emoji = EmojiGuesser.product(name: name, category: category)
        }
        product.category = category
        product.ingredients = builtIngredients
        product.overheads = builtOverheads
        product.yieldMode = yieldMode
        product.yieldUnit = yieldUnit
        // The profit % is derived from the selling price the user typed in.
        product.desiredProfitPercent = summary.desiredProfitPercent
        switch yieldMode {
        case .target:
            product.targetYield = yieldValue
            product.actualYield = Fmt.parseInt(actualYieldText).flatMap { $0 > 0 ? $0 : nil }
        case .actual:
            product.actualYield = yieldValue
            product.targetYield = Fmt.parseInt(targetYieldText).flatMap { $0 > 0 ? $0 : nil } ?? yieldValue
        }

        store.saveProduct(product)

        original = product
        existingImageFileName = product.imageFileName
        existingImageData = product.imageData
        newImageData = nil
        userRemovedImage = false
        savedProductName = product.name
        savedProductID = product.id
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { showSuccess = true }
    }

    // MARK: Reset

    func resetForNewProduct() {
        original = nil
        name = ""
        productDescription = ""
        category = nil
        newImageData = nil
        existingImageFileName = nil
        existingImageAssetName = nil
        existingImageData = nil
        userRemovedImage = false
        selections = [:]
        orphanIngredients = []
        ingredientSearch = ""
        showIngredientValidation = false
        overheadDrafts = []
        yieldMode = .target
        targetYieldText = ""
        actualYieldText = ""
        sellingPriceText = ""
        yieldUnit = "pcs"
        nameError = nil
        categoryError = nil
        ingredientError = nil
        overheadError = nil
        yieldError = nil
        sellingPriceError = nil
        calculated = nil
        step = .details
        withAnimation { showSuccess = false }
    }
}
