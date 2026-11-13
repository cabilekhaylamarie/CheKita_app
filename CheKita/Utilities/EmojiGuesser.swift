import Foundation

/// Picks a friendly emoji thumbnail when the user hasn't added a photo.
enum EmojiGuesser {
    private static let materialKeywords: [(String, String)] = [
        ("flour", "🌾"), ("sugar", "🍚"), ("butter", "🧈"), ("margarine", "🧈"), ("egg", "🥚"),
        ("milk", "🥛"), ("cream", "🍦"), ("cocoa", "🍫"), ("chocolate", "🍫"), ("vanilla", "🌼"),
        ("cheese", "🧀"), ("coffee", "☕️"), ("tea", "🍵"), ("salt", "🧂"), ("oil", "🫒"),
        ("yeast", "🍞"), ("baking", "🧪"), ("banana", "🍌"), ("strawberr", "🍓"), ("lemon", "🍋"),
        ("ube", "🍠"), ("coconut", "🥥"), ("honey", "🍯"), ("nut", "🥜"), ("water", "💧"),
        ("color", "🎨"), ("cup", "🥤"), ("box", "📦"), ("bag", "🛍️"), ("liner", "🧁"), ("label", "🏷️")
    ]

    private static let productKeywords: [(String, String)] = [
        ("cookie", "🍪"), ("cake", "🍰"), ("cupcake", "🧁"), ("muffin", "🧁"), ("brownie", "🍫"),
        ("pandesal", "🍞"), ("bread", "🍞"), ("roll", "🥐"), ("croissant", "🥐"), ("flan", "🍮"),
        ("pudding", "🍮"), ("coffee", "🧋"), ("tea", "🧋"), ("juice", "🧃"), ("shake", "🥤"),
        ("pie", "🥧"), ("donut", "🍩"), ("doughnut", "🍩"), ("ice cream", "🍨"), ("candy", "🍬")
    ]

    static func material(name: String, category: MaterialCategory) -> String {
        let lower = name.lowercased()
        if let match = materialKeywords.first(where: { lower.contains($0.0) }) { return match.1 }
        switch category {
        case .dryGoods: return "🌾"
        case .dairy: return "🥛"
        case .packaging: return "📦"
        case .others: return "🧺"
        }
    }

    static func product(name: String, category: ProductCategory) -> String {
        let lower = name.lowercased()
        if let match = productKeywords.first(where: { lower.contains($0.0) }) { return match.1 }
        return category.defaultEmoji
    }
}
