import SwiftUI
import FirebaseCore

/// Configures Firebase as soon as the app launches (recommended setup for SwiftUI apps).
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        ServiceFactory.configureFirebase()
        return true
    }
}

@main
struct CheKitaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var session: SessionViewModel
    @StateObject private var store = DataStore()
    @StateObject private var router = AppRouter()

    init() {
        // Also configured here so Firebase is ready before any view model touches it.
        // (`configureFirebase` is idempotent.)
        ServiceFactory.configureFirebase()
        _session = StateObject(wrappedValue: SessionViewModel(auth: ServiceFactory.makeAuthService()))
        CheKitaApp.configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .environmentObject(store)
                .environmentObject(router)
                .tint(CKColor.primary)
                .preferredColorScheme(.light)
        }
    }

    private static func configureAppearance() {
        UISegmentedControl.appearance().selectedSegmentTintColor = CKColor.uiPrimary
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        UISwitch.appearance().onTintColor = CKColor.uiPrimary
    }
}
