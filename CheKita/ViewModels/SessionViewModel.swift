import Foundation

@MainActor
final class SessionViewModel: ObservableObject {
    enum Stage: Equatable { case splash, onboarding, auth, main }
    enum AuthScreen: Equatable { case login, signUp }

    @Published var stage: Stage = .splash
    @Published var authScreen: AuthScreen = .login
    @Published private(set) var currentUser: AppUser?

    let auth: AuthService
    private let onboardingKey = "chekita.hasSeenOnboarding"

    init(auth: AuthService) {
        self.auth = auth
    }

    var hasSeenOnboarding: Bool { UserDefaults.standard.bool(forKey: onboardingKey) }

    func finishSplash() async {
        if let user = await auth.restoreSession() {
            currentUser = user
            stage = .main
        } else {
            stage = hasSeenOnboarding ? .auth : .onboarding
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingKey)
        authScreen = .login
        stage = .auth
    }

    func signIn(email: String, password: String) async throws {
        let user = try await auth.signIn(email: email, password: password)
        currentUser = user
        stage = .main
    }

    func signUp(fullName: String, email: String, password: String) async throws {
        let user = try await auth.signUp(fullName: fullName, email: email, password: password)
        currentUser = user
        stage = .main
    }

    func updateProfile(_ user: AppUser) async throws {
        currentUser = try await auth.updateProfile(user)
    }

    /// Saves a new profile photo (or removes it when `imageData` is nil).
    /// The sharp copy stays on this device; a small thumbnail goes on the user document
    /// in Firestore, so the photo survives a reinstall. No Firebase Storage, no cost.
    func updateAvatar(imageData: Data?) async throws {
        guard var user = currentUser else { throw AuthError.notSignedIn }
        let oldFileName = user.avatarFileName

        if let imageData {
            guard let fileName = ImageStore.shared.save(imageData) else {
                throw AuthError.underlying("That photo couldn't be used. Please pick another.")
            }
            user.avatarFileName = fileName
            user.avatarData = ImageStore.shared.thumbnailBase64(from: imageData, maxDimension: 320)
        } else {
            user.avatarFileName = nil
            user.avatarData = nil
        }

        do {
            currentUser = try await auth.updateProfile(user)
        } catch {
            if imageData != nil { ImageStore.shared.delete(user.avatarFileName) }
            throw error
        }
        if oldFileName != user.avatarFileName { ImageStore.shared.delete(oldFileName) }
    }

    func signOut() {
        try? auth.signOut()
        currentUser = nil
        authScreen = .login
        stage = .auth
    }
}
