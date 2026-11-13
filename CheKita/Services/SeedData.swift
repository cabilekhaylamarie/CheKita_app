import Foundation

/// Sample workspace matching the CheKita design references.
/// Photos: add images to Assets.xcassets using the `imageAssetName` values below
/// (e.g. "food_chocolate_chip_cookie") and they'll replace the emoji thumbnails automatically.
enum SeedData {
    struct Workspace {
        let materials: [Material]
        let products: [Product]
        let records: [ProductionRecord]
        let sales: [SaleRecord]
    }

    static func make() -> Workspace {
        let now = Date()
        var order = 0
        func stamp() -> Date {
            order += 1
            return now.addingTimeInterval(-Double(order) * 60)
        }

        func material(_ name: String, _ category: MaterialCategory, _ unit: MeasurementUnit,
                      cost: Double, per quantity: Double = 1, stock: Double, emoji: String, asset: String) -> Material {
            let date = stamp()
            return Material(name: name, category: category, unit: unit, cost: cost, costQuantity: quantity,
                            currentStock: stock, emoji: emoji, imageAssetName: asset, createdAt: date, updatedAt: date)
        }

        let materials: [Material] = [
            material("All-Purpose Flour", .dryGoods, .kg, cost: 60, stock: 2, emoji: "🌾", asset: "material_all_purpose_flour"),
            material("White Sugar", .dryGoods, .kg, cost: 55, stock: 1, emoji: "🍚", asset: "material_white_sugar"),
            material("Butter", .dairy, .g, cost: 120, per: 500, stock: 500, emoji: "🧈", asset: "material_butter"),
            material("Eggs", .others, .pcs, cost: 8, stock: 12, emoji: "🥚", asset: "material_eggs"),
            material("Cocoa Powder", .dryGoods, .g, cost: 95, per: 250, stock: 250, emoji: "🍫", asset: "material_cocoa_powder"),
            material("Vanilla Extract", .others, .ml, cost: 150, per: 100, stock: 100, emoji: "🌼", asset: "material_vanilla_extract"),
            material("Fresh Milk", .dairy, .L, cost: 95, stock: 1, emoji: "🥛", asset: "material_fresh_milk"),
            material("Chocolate Chips", .dryGoods, .kg, cost: 150, stock: 1, emoji: "🍫", asset: "material_chocolate_chips"),
            material("Condensed Milk", .dairy, .ml, cost: 65, per: 300, stock: 900, emoji: "🥫", asset: "material_condensed_milk"),
            material("Cheese", .dairy, .g, cost: 110, per: 165, stock: 330, emoji: "🧀", asset: "material_cheese"),
            material("Instant Yeast", .dryGoods, .g, cost: 60, per: 100, stock: 100, emoji: "🍞", asset: "material_instant_yeast"),
            material("Instant Coffee", .others, .g, cost: 180, per: 200, stock: 200, emoji: "☕️", asset: "material_instant_coffee"),
            material("Red Food Coloring", .others, .ml, cost: 45, per: 30, stock: 30, emoji: "🎨", asset: "material_red_food_coloring"),
            material("Packaging Box", .packaging, .pcs, cost: 5, stock: 50, emoji: "📦", asset: "material_packaging_box"),
            material("Cupcake Liners", .packaging, .pcs, cost: 1, stock: 100, emoji: "🧁", asset: "material_cupcake_liners"),
            material("Plastic Cups", .packaging, .pcs, cost: 3, stock: 50, emoji: "🥤", asset: "material_plastic_cups")
        ]

        let byName = Dictionary(uniqueKeysWithValues: materials.map { ($0.name, $0) })
        func ing(_ name: String, _ quantity: Double, _ unit: MeasurementUnit) -> ProductIngredient? {
            guard let m = byName[name] else { return nil }
            return ProductIngredient(materialID: m.id, materialName: m.name, materialEmoji: m.emoji,
                                     quantity: quantity, unit: unit, costPerBaseUnit: m.costPerBaseUnit)
        }

        /// Labor, gas and packaging examples so the costing shows more than ingredients.
        func labor(_ amount: Double) -> OverheadCost {
            OverheadCost(name: "Labor", amount: amount, basis: .perBatch, icon: "person.2")
        }
        func gas(_ amount: Double) -> OverheadCost {
            OverheadCost(name: "Gas / Electricity", amount: amount, basis: .perBatch, icon: "flame")
        }
        func packaging(_ amount: Double, basis: OverheadBasis = .perBatch) -> OverheadCost {
            OverheadCost(name: "Packaging", amount: amount, basis: basis, icon: "shippingbox")
        }

        func product(_ name: String, _ category: ProductCategory, desc: String, emoji: String, asset: String,
                     yield: Int, unit: String = "pcs", profit: Double, stock: Int,
                     overheads: [OverheadCost] = [],
                     _ ingredients: [ProductIngredient?]) -> Product {
            let date = stamp()
            return Product(name: name, description: desc, category: category, emoji: emoji, imageAssetName: asset,
                           ingredients: ingredients.compactMap { $0 }, overheads: overheads,
                           targetYield: yield, yieldUnit: unit,
                           desiredProfitPercent: profit, stock: stock, createdAt: date, updatedAt: date)
        }

        let cookie = product("Chocolate Chip Cookie", .cookies,
                             desc: "Soft and chewy homemade cookies\nwith chocolate chips.",
                             emoji: "🍪", asset: "food_chocolate_chip_cookie", yield: 20, profit: 30, stock: 20,
                             overheads: [labor(50), gas(20), packaging(5)], [
                                ing("All-Purpose Flour", 200, .g), ing("White Sugar", 100, .g), ing("Butter", 100, .g),
                                ing("Eggs", 1, .pcs), ing("Chocolate Chips", 100, .g)
                             ])
        let redVelvet = product("Red Velvet Cake", .cakes,
                                desc: "Moist red velvet layers with a light cocoa flavor.",
                                emoji: "🍰", asset: "food_red_velvet_cake", yield: 8, profit: 40, stock: 5,
                                overheads: [labor(120), gas(45)], [
                                    ing("All-Purpose Flour", 250, .g), ing("White Sugar", 200, .g), ing("Butter", 125, .g),
                                    ing("Eggs", 2, .pcs), ing("Cocoa Powder", 15, .g), ing("Fresh Milk", 240, .ml),
                                    ing("Red Food Coloring", 10, .ml), ing("Packaging Box", 1, .pcs)
                                ])
        let cupcake = product("Vanilla Cupcake", .pastries,
                              desc: "Fluffy vanilla cupcakes topped with buttercream.",
                              emoji: "🧁", asset: "food_vanilla_cupcake", yield: 12, profit: 35, stock: 12,
                              overheads: [labor(60), gas(25), packaging(2, basis: .perPiece)], [
                                ing("All-Purpose Flour", 150, .g), ing("White Sugar", 120, .g), ing("Butter", 100, .g),
                                ing("Eggs", 2, .pcs), ing("Vanilla Extract", 5, .ml), ing("Fresh Milk", 120, .ml),
                                ing("Cupcake Liners", 12, .pcs)
                              ])
        let pandesal = product("Pandesal", .breads,
                               desc: "Classic soft Filipino bread rolls.",
                               emoji: "🍞", asset: "food_pandesal", yield: 50, profit: 30, stock: 50, [
                                ing("All-Purpose Flour", 1, .kg), ing("White Sugar", 100, .g), ing("Instant Yeast", 10, .g),
                                ing("Butter", 60, .g), ing("Eggs", 1, .pcs), ing("Fresh Milk", 250, .ml)
                               ])
        let flan = product("Leche Flan", .desserts,
                           desc: "Silky caramel custard made with fresh eggs.",
                           emoji: "🍮", asset: "food_leche_flan", yield: 8, profit: 35, stock: 8, [
                            ing("Eggs", 10, .pcs), ing("Condensed Milk", 300, .ml), ing("Fresh Milk", 200, .ml),
                            ing("White Sugar", 150, .g), ing("Vanilla Extract", 5, .ml)
                           ])
        let coffee = product("Iced Coffee", .drinks,
                             desc: "Creamy sweet iced coffee.",
                             emoji: "🧋", asset: "food_iced_coffee", yield: 10, unit: "cups", profit: 50, stock: 15,
                             overheads: [labor(30), packaging(3, basis: .perPiece)], [
                                ing("Instant Coffee", 20, .g), ing("Fresh Milk", 500, .ml), ing("Condensed Milk", 150, .ml),
                                ing("White Sugar", 50, .g), ing("Plastic Cups", 10, .pcs)
                             ])
        let cheeseRoll = product("Cheese Roll", .others,
                                 desc: "Buttery bread rolls filled with cheese.",
                                 emoji: "🥐", asset: "food_cheese_roll", yield: 10, profit: 35, stock: 10, [
                                    ing("All-Purpose Flour", 300, .g), ing("Butter", 80, .g), ing("White Sugar", 60, .g),
                                    ing("Cheese", 165, .g), ing("Eggs", 1, .pcs), ing("Instant Yeast", 7, .g)
                                 ])

        let products = [cookie, redVelvet, cupcake, pandesal, flan, coffee, cheeseRoll]

        // Brownies appear in the Reports reference but not in the product list.
        let brownies = product("Brownies", .desserts, desc: "Fudgy chocolate brownies.",
                               emoji: "🍫", asset: "food_brownies", yield: 25, profit: 30, stock: 0, [
                                ing("All-Purpose Flour", 125, .g), ing("White Sugar", 200, .g), ing("Butter", 115, .g),
                                ing("Eggs", 2, .pcs), ing("Cocoa Powder", 40, .g), ing("Chocolate Chips", 80, .g)
                               ])
        var cheeseRollAsBread = cheeseRoll
        cheeseRollAsBread.category = .breads

        func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
            Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: 9)) ?? now
        }
        func record(_ p: Product, _ quantity: Int, _ date: Date) -> ProductionRecord {
            ProductionRecordBuilder.build(product: p, ingredients: p.ingredients, quantity: quantity,
                                          date: date, notes: "", materialsDeducted: false)
        }

        let records = [
            record(cookie, 20, day(2026, 5, 10)),
            record(cupcake, 30, day(2026, 5, 8)),
            record(brownies, 25, day(2026, 5, 5)),
            record(redVelvet, 15, day(2026, 5, 2)),
            record(coffee, 20, day(2026, 4, 25)),
            record(cheeseRollAsBread, 50, day(2026, 4, 20))
        ]

        // Sample sales, dated around today so the Reports and Home figures are alive.
        func daysAgo(_ days: Int, hour: Int = 14) -> Date {
            let start = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
            return Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: start) ?? start
        }
        func sale(_ p: Product, _ quantity: Int, _ date: Date,
                  channel: SaleChannel = .walkIn, customer: String = "", price: Double? = nil) -> SaleRecord {
            let ingredientCost = p.ingredients.reduce(0) { $0 + $1.cost }
            let summary = CostCalculator.summary(ingredientCost: ingredientCost,
                                                 overheadCost: p.overheadCost,
                                                 yield: p.effectiveYield,
                                                 profitPercent: p.desiredProfitPercent)
            let unitPrice = price ?? max(1, (summary.suggestedSRP).rounded())
            return SaleRecord(productID: p.id,
                              productName: p.name,
                              productCategory: p.category,
                              productEmoji: p.emoji,
                              imageAssetName: p.imageAssetName,
                              date: date,
                              quantity: quantity,
                              unitLabel: p.yieldUnit,
                              unitPrice: unitPrice,
                              unitCost: summary.costPerPiece,
                              channel: channel,
                              customer: customer,
                              createdAt: date)
        }

        let sales: [SaleRecord] = [
            sale(cookie, 12, daysAgo(0), channel: .walkIn),
            sale(cupcake, 6, daysAgo(1), channel: .order, customer: "Aling Nena"),
            sale(coffee, 8, daysAgo(2), channel: .walkIn),
            sale(pandesal, 30, daysAgo(3), channel: .walkIn),
            sale(redVelvet, 2, daysAgo(5), channel: .order, customer: "Birthday order"),
            sale(cheeseRoll, 10, daysAgo(7), channel: .reseller, customer: "Sari-sari store"),
            sale(cookie, 20, daysAgo(9), channel: .online, customer: "Facebook order"),
            sale(flan, 4, daysAgo(12), channel: .order, customer: "Office pasalubong")
        ]

        return Workspace(materials: materials, products: products, records: records, sales: sales)
    }
}
