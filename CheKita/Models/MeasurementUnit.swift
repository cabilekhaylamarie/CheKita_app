import Foundation

/// The physical dimension a unit measures. Only units of the same dimension can be converted.
enum UnitDimension: String, Codable {
    case mass, volume, count
}

enum MeasurementUnit: String, Codable, CaseIterable, Identifiable {
    case kg, g, L, ml, tbsp, tsp, cup, pcs, dozen

    var id: String { rawValue }

    var dimension: UnitDimension {
        switch self {
        case .kg, .g: return .mass
        case .L, .ml, .tbsp, .tsp, .cup: return .volume
        case .pcs, .dozen: return .count
        }
    }

    /// Multiplier converting 1 of this unit into its base unit (g, ml or pc).
    var toBaseFactor: Double {
        switch self {
        case .kg: return 1000
        case .g: return 1
        case .L: return 1000
        case .ml: return 1
        case .tbsp: return 14.7868
        case .tsp: return 4.92892
        case .cup: return 236.588
        case .pcs: return 1
        case .dozen: return 12
        }
    }

    var displayName: String {
        switch self {
        case .kg: return "kg – Kilogram"
        case .g: return "g – Gram"
        case .L: return "L – Liter"
        case .ml: return "ml – Milliliter"
        case .tbsp: return "tbsp – Tablespoon"
        case .tsp: return "tsp – Teaspoon"
        case .cup: return "cup – Cup"
        case .pcs: return "pcs – Pieces"
        case .dozen: return "dozen – Dozen"
        }
    }

    /// Short label that reads naturally next to a quantity ("1 pc", "12 pcs", "200 g").
    func label(for quantity: Double) -> String {
        if self == .pcs { return quantity == 1 ? "pc" : "pcs" }
        return rawValue
    }

    var compatibleUnits: [MeasurementUnit] {
        MeasurementUnit.allCases.filter { $0.dimension == dimension }
    }

    /// The most practical unit to type a recipe quantity in for a material bought in `self`.
    var defaultRecipeUnit: MeasurementUnit {
        switch dimension {
        case .mass: return .g
        case .volume: return .ml
        case .count: return .pcs
        }
    }
}
