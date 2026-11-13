import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Firebase Authentication (email/password). The profile is stored at users/{uid}.
/// Firebase keeps the session in the keychain, so users stay logged in between launches.
final class FirebaseAuthService: AuthService {
    let supportsDirectPasswordReset = false

    private var auth: Auth { Auth.auth() }
    private var users: CollectionReference { Firestore.firestore().collection("users") }

    func restoreSession() async -> AppUser? {
        guard let firebaseUser = auth.currentUser else { return nil }
        do {
            // Detects accounts that were disabled or deleted since the last launch.
            try await firebaseUser.reload()
        } catch {
            if let code = Self.authCode(error), [.userDisabled, .userNotFound, .userTokenExpired, .invalidUserToken].contains(code) {
                try? auth.signOut()
                return nil
            }
            // Offline or transient error: keep the cached session.
        }
        return await loadProfile(for: auth.currentUser ?? firebaseUser)
    }

    func signIn(email: String, password: String) async throws -> AppUser {
        do {
            let result = try await auth.signIn(withEmail: email.trimmed, password: password)
            return await loadProfile(for: result.user)
        } catch {
            throw Self.friendly(error)
        }
    }

    func signUp(fullName: String, email: String, password: String) async throws -> AppUser {
        let result: AuthDataResult
        do {
            result = try await auth.createUser(withEmail: email.trimmed, password: password)
        } catch {
            throw Self.friendly(error)
        }

        let change = result.user.createProfileChangeRequest()
        change.displayName = fullName.trimmed
        try? await change.commitChanges()

        let user = AppUser(id: result.user.uid, fullName: fullName.trimmed, email: email.trimmed.lowercased())
        var data = profileData(user)
        data["createdAt"] = FieldValue.serverTimestamp()
        do {
            try await users.document(user.id).setData(data, merge: true)
        } catch {
            // The account exists; the profile document is written again on the next profile update.
            #if DEBUG
            print("CheKita Auth: profile write failed: \(error.localizedDescription)")
            #endif
        }
        return user
    }

    func signOut() throws {
        try auth.signOut()
    }

    func updateProfile(_ user: AppUser) async throws -> AppUser {
        guard auth.currentUser?.uid == user.id else { throw AuthError.notSignedIn }
        do {
            try await users.document(user.id).setData(profileData(user), merge: true)
            if let firebaseUser = auth.currentUser, firebaseUser.displayName != user.fullName {
                let change = firebaseUser.createProfileChangeRequest()
                change.displayName = user.fullName
                try? await change.commitChanges()
            }
            return user
        } catch {
            throw Self.friendly(error)
        }
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let firebaseUser = auth.currentUser, let email = firebaseUser.email else {
            throw AuthError.notSignedIn
        }
        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
            _ = try await firebaseUser.reauthenticate(with: credential)
        } catch {
            if let code = Self.authCode(error), [.wrongPassword, .invalidCredential].contains(code) {
                throw AuthError.wrongCurrentPassword
            }
            throw Self.friendly(error)
        }
        do {
            try await firebaseUser.updatePassword(to: newPassword)
        } catch {
            throw Self.friendly(error)
        }
    }

    func sendPasswordReset(email: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: email.trimmed)
        } catch {
            throw Self.friendly(error)
        }
    }

    func resetPassword(email: String, newPassword: String) async throws {
        // Firebase resets passwords through the emailed link (see sendPasswordReset).
        throw AuthError.unsupported
    }

    // MARK: Profile

    private func loadProfile(for firebaseUser: FirebaseAuth.User) async -> AppUser {
        var user = AppUser(id: firebaseUser.uid,
                           fullName: firebaseUser.displayName ?? "",
                           email: firebaseUser.email ?? "")
        do {
            let snapshot = try await users.document(firebaseUser.uid).getDocument()
            if let data = snapshot.data() {
                user.fullName = (data["fullName"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? user.fullName
                user.businessName = data["businessName"] as? String ?? ""
                user.notificationsEnabled = data["notificationsEnabled"] as? Bool ?? true
                user.avatarData = data["avatarData"] as? String
                if let timestamp = data["createdAt"] as? Timestamp { user.createdAt = timestamp.dateValue() }
            } else {
                // First login for an account created elsewhere: create the profile document.
                var data = profileData(user)
                data["createdAt"] = FieldValue.serverTimestamp()
                try? await users.document(user.id).setData(data, merge: true)
            }
        } catch {
            #if DEBUG
            print("CheKita Auth: profile read failed: \(error.localizedDescription)")
            #endif
        }
        return user
    }

    private func profileData(_ user: AppUser) -> [String: Any] {
        [
            "uid": user.id,
            "fullName": user.fullName,
            "email": user.email,
            "businessName": user.businessName,
            "notificationsEnabled": user.notificationsEnabled,
            "avatarData": user.avatarData ?? NSNull(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
    }

    // MARK: Errors

    private static func authCode(_ error: Error) -> AuthErrorCode? {
        let nsError = error as NSError
        guard nsError.domain == AuthErrors.domain else { return nil }
        return AuthErrorCode(rawValue: nsError.code)
    }

    static func friendly(_ error: Error) -> AuthError {
        if let authError = error as? AuthError { return authError }
        guard let code = authCode(error) else {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                return .underlying("No internet connection. Please check your network and try again.")
            }
            return .underlying(error.localizedDescription)
        }
        switch code {
        case .wrongPassword, .invalidCredential, .userNotFound:
            return .invalidCredentials
        case .emailAlreadyInUse:
            return .emailInUse
        case .invalidEmail:
            return .underlying("Enter a valid email address.")
        case .weakPassword:
            return .underlying("Password is too weak. Use at least 6 characters.")
        case .networkError:
            return .underlying("No internet connection. Please check your network and try again.")
        case .tooManyRequests:
            return .underlying("Too many attempts. Please wait a moment and try again.")
        case .userDisabled:
            return .underlying("This account has been disabled.")
        case .requiresRecentLogin:
            return .underlying("For your security, please log out and log in again, then retry.")
        case .operationNotAllowed:
            return .underlying("Email/password sign-in isn't enabled for this Firebase project.")
        default:
            return .underlying(error.localizedDescription)
        }
    }
}
