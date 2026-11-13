import Foundation

/// Whether an extra cost is paid once for the whole batch or for every piece produced.
enum OverheadBasis: String, Codable, CaseIterable, Identifiable {
    case perBatch = "Per Batch"
    case perPiece = "Per Piece"

    var id: String { rawValue }

    var shortLabel: String { self == .perBatch ? "batch" : "piece" }
}

/// A non-ingredient cost: labor, gas/electricity, packaging, delivery, rent share, etc.
/// These are added to the ingredient cost so cost per piece and SRP reflect real expenses.
struct OverheadCost: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var amount: Double
    var basis: OverheadBasis
    var icon: String

    init(id: UUID = UUID(), name: String, amount: Double, basis: OverheadBasis = .perBatch, icon: String = "plus.circle") {
        self.id = id
        self.name = name
        self.amount = amount
        self.basis = basis
        self.icon = icon
    }

    /// Cost of this line for a batch of `yield` pieces.
    func total(forYield yield: Int) -> Double {
        guard amount > 0 else { return 0 }
        switch basis {
        case .perBatch: return amount
        case .perPiece: return amount * Double(max(0, yield))
        }
    }

    /// "₱50.00 per batch" / "₱5.00 per piece"
    var amountLabel: String { "\(Fmt.peso(amount)) per \(basis.shortLabel)" }
}

extension OverheadCost {
    /// Quick-add buttons offered in the Profit Calculator step.
    struct Preset: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let basis: OverheadBasis
    }

    static let presets: [Preset] = [
        Preset(name: "Labor", icon: "person.2", basis: .perBatch),
        Preset(name: "Gas / Electricity", icon: "flame", basis: .perBatch),
        Preset(name: "Packaging", icon: "shippingbox", basis: .perPiece),
        Preset(name: "Delivery", icon: "box.truck", basis: .perBatch),
        Preset(name: "Other Cost", icon: "plus.circle", basis: .perBatch)
    ]

    init(preset: Preset) {
        self.init(name: preset.name, amount: 0, basis: preset.basis, icon: preset.icon)
    }
}

/// Total of a set of overhead lines for one batch.
extension Array where Element == OverheadCost {
    func totalCost(forYield yield: Int) -> Double {
        reduce(0) { $0 + $1.total(forYield: yield) }
    }
}
