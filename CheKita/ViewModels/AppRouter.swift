import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case home, products, inventory, reports, profile

    var title: String {
        switch self {
        case .home: return "Home"
        case .products: return "Products"
        case .inventory: return "Inventory"
        case .reports: return "Reports"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .products: return "bag"
        case .inventory: return "shippingbox"
        case .reports: return "chart.bar"
        case .profile: return "person"
        }
    }

    var selectedIcon: String { icon + ".fill" }
}

enum AppRoute: Hashable {
    case productDetail(UUID)
    case materialForm(UUID?)
    case recipeReport(UUID)
    case editProfile
    case notifications
    case changePassword
    case appSettings
    case about
    case legal(LegalDocument)
}

enum LegalDocument: String, Hashable, Identifiable {
    case terms = "Terms & Conditions"
    case privacy = "Privacy Policy"

    var id: String { rawValue }
}

struct CreateProductContext: Identifiable {
    let id = UUID()
    let editingProductID: UUID?
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var selectedTab: AppTab = .home
    @Published var paths: [AppTab: [AppRoute]] = [:]
    @Published var createProductContext: CreateProductContext?

    func path(for tab: AppTab) -> Binding<[AppRoute]> {
        Binding(
            get: { self.paths[tab] ?? [] },
            set: { self.paths[tab] = $0 }
        )
    }

    var isAtRoot: Bool { (paths[selectedTab] ?? []).isEmpty }

    func select(_ tab: AppTab) {
        if selectedTab == tab {
            popToRoot(tab)
        } else {
            selectedTab = tab
        }
    }

    func push(_ route: AppRoute, in tab: AppTab? = nil) {
        paths[tab ?? selectedTab, default: []].append(route)
    }

    func popToRoot(_ tab: AppTab? = nil) {
        paths[tab ?? selectedTab] = []
    }

    func startCreateProduct() {
        createProductContext = CreateProductContext(editingProductID: nil)
    }

    func startEditProduct(_ id: UUID) {
        createProductContext = CreateProductContext(editingProductID: id)
    }

    func showProductList() {
        selectedTab = .products
        popToRoot(.products)
    }

    func reset() {
        selectedTab = .home
        paths = [:]
        createProductContext = nil
    }
}
