import Foundation

protocol AuthService {
    /// Local accounts can reset a password on-device; Firebase sends a reset email instead.
    var supportsDirectPasswordReset: Bool { get }

    func restoreSession() async -> AppUser?
    func signIn(email: String, password: String) async throws -> AppUser
    func signUp(fullName: String, email: String, password: String) async throws -> AppUser
    func signOut() throws
    func updateProfile(_ user: AppUser) async throws -> AppUser
    func changePassword(currentPassword: String, newPassword: String) async throws
    func sendPasswordReset(email: String) async throws
    func resetPassword(email: String, newPassword: String) async throws
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case emailInUse
    case accountNotFound
    case wrongCurrentPassword
    case notSignedIn
    case unsupported
    case underlying(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Incorrect email or password."
        case .emailInUse: return "An account with this email already exists."
        case .accountNotFound: return "No account found with this email."
        case .wrongCurrentPassword: return "Your current password is incorrect."
        case .notSignedIn: return "You need to log in again."
        case .unsupported: return "This action isn't available right now."
        case .underlying(let message): return message
        }
    }
}
