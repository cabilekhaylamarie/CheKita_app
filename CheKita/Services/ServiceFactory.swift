import Foundation
import FirebaseCore

/// Creates the Firebase-backed services used across the app.
enum ServiceFactory {
    /// Configures Firebase from the bundled GoogleService-Info.plist (called once at launch).
    static func configureFirebase() {
        guard FirebaseApp.app() == nil else { return }
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            assertionFailure("GoogleService-Info.plist is missing from the CheKita target.")
            return
        }
        FirebaseApp.configure()
    }

    static var isFirebaseConfigured: Bool { FirebaseApp.app() != nil }

    static func makeAuthService() -> AuthService {
        FirebaseAuthService()
    }

    static func makeRepository(userID: String) -> DataRepository {
        FirebaseDataRepository(userID: userID)
    }
}
