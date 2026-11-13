import SwiftUI

/// Hosts one NavigationStack per tab (state is preserved when switching) and the custom
/// CheKita tab bar, which is only shown on the tab root screens.
struct MainTabView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var store: DataStore
    @StateObject private var keyboard = KeyboardObserver()

    private var showsTabBar: Bool {
        router.isAtRoot && router.createProductContext == nil && !keyboard.isVisible
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    let isSelected = router.selectedTab == tab
                    TabStack(tab: tab)
                        .opacity(isSelected ? 1 : 0)
                        .allowsHitTesting(isSelected)
                        .accessibilityHidden(!isSelected)
                        .zIndex(isSelected ? 1 : 0)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showsTabBar {
                CKTabBar()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showsTabBar)
        .overlay {
            if !store.isLoaded {
                ZStack {
                    Color.white.opacity(0.85).ignoresSafeArea()
                    ProgressView("Loading your workspace…")
                        .tint(CKColor.primary)
                        .foregroundStyle(CKColor.textSecondary)
                }
                .transition(.opacity)
            } else if let loadError = store.loadError {
                WorkspaceLoadErrorView(message: loadError)
                    .transition(.opacity)
            }
        }
        .fullScreenCover(item: $router.createProductContext) { context in
            CreateProductView(store: store, editingProductID: context.editingProductID)
                .environmentObject(store)
                .environmentObject(router)
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { store.lastError != nil },
            set: { if !$0 { store.lastError = nil } }
        )) {
            Button("OK", role: .cancel) { store.lastError = nil }
        } message: {
            Text(store.lastError ?? "")
        }
    }
}

private struct TabStack: View {
    let tab: AppTab
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        NavigationStack(path: router.path(for: tab)) {
            root
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: AppRoute.self) { route in
                    RouteDestinationView(route: route)
                        .toolbar(.hidden, for: .navigationBar)
                }
        }
    }

    @ViewBuilder
    private var root: some View {
        switch tab {
        case .home: HomeView()
        case .products: ProductListView()
        case .inventory: InventoryListView()
        case .reports: ReportsView()
        case .profile: ProfileView()
        }
    }
}

struct RouteDestinationView: View {
    let route: AppRoute

    var body: some View {
        switch route {
        case .productDetail(let id): ProductDetailView(productID: id)
        case .materialForm(let id): MaterialFormView(materialID: id)
        case .recipeReport(let id): RecipeReportView(recordID: id)
        case .editProfile: EditProfileView()
        case .notifications: NotificationSettingsView()
        case .changePassword: ChangePasswordView()
        case .appSettings: AppSettingsView()
        case .about: AboutView()
        case .legal(let document): LegalDocumentView(document: document)
        }
    }
}

/// Bottom navigation: Home, Products, Inventory, Reports, Profile with teal active state.
struct CKTabBar: View {
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                let isSelected = router.selectedTab == tab
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    router.select(tab)
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                            .font(.system(size: 20, weight: .regular))
                            .frame(height: 24)
                        Text(tab.title)
                            .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                        Capsule()
                            .fill(isSelected ? CKColor.primary : Color.clear)
                            .frame(width: 26, height: 2)
                    }
                    .foregroundStyle(isSelected ? CKColor.primary : CKColor.navy)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.bottom, 2)
        .background(
            Color.white
                .overlay(alignment: .top) { Rectangle().fill(CKColor.border).frame(height: 1) }
                .shadow(color: CKColor.navy.opacity(0.05), radius: 8, y: -3)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

/// Shown when the workspace couldn't be loaded from Firestore (e.g. offline on first launch).
private struct WorkspaceLoadErrorView: View {
    let message: String
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var session: SessionViewModel
    @State private var isRetrying = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 30))
                    .foregroundStyle(CKColor.primary)
                    .frame(width: 70, height: 70)
                    .background(Circle().fill(CKColor.aqua))
                Text("Can't reach CheKita Cloud")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(CKColor.navy)
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(CKColor.textSecondary)
                    .multilineTextAlignment(.center)
                Button {
                    isRetrying = true
                    Task {
                        await store.retryLoad()
                        isRetrying = false
                    }
                } label: {
                    if isRetrying { ProgressView().tint(.white) } else { Text("Try Again") }
                }
                .buttonStyle(.ckPrimary)
                .disabled(isRetrying)
                Button("Log Out") { session.signOut() }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CKColor.primary)
            }
            .padding(32)
        }
    }
}
