import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email = "" { didSet { emailError = nil; formError = nil } }
    @Published var password = "" { didSet { passwordError = nil; formError = nil } }
    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var formError: String?
    @Published var isLoading = false

    func login(session: SessionViewModel) async {
        emailError = Validators.emailError(email)
        passwordError = password.isEmpty ? "Password is required." : nil
        guard emailError == nil, passwordError == nil else { return }

        isLoading = true
        defer { isLoading = false }
        do {
            try await session.signIn(email: email, password: password)
        } catch {
            formError = error.localizedDescription
        }
    }
}

@MainActor
final class SignUpViewModel: ObservableObject {
    @Published var fullName = "" { didSet { fullNameError = nil; formError = nil } }
    @Published var email = "" { didSet { emailError = nil; formError = nil } }
    @Published var password = "" { didSet { passwordError = nil; formError = nil } }
    @Published var confirmPassword = "" { didSet { confirmError = nil; formError = nil } }
    @Published var agreedToTerms = false { didSet { termsError = nil } }

    @Published var fullNameError: String?
    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var confirmError: String?
    @Published var termsError: String?
    @Published var formError: String?
    @Published var isLoading = false

    func signUp(session: SessionViewModel) async {
        fullNameError = fullName.trimmed.isEmpty ? "Full name is required." : nil
        emailError = Validators.emailError(email)
        passwordError = Validators.passwordError(password)
        if confirmPassword.isEmpty {
            confirmError = "Please confirm your password."
        } else if confirmPassword != password {
            confirmError = "Passwords do not match."
        } else {
            confirmError = nil
        }
        termsError = agreedToTerms ? nil : "Please accept the Terms and Conditions to continue."

        guard [fullNameError, emailError, passwordError, confirmError, termsError].allSatisfy({ $0 == nil }) else { return }

        isLoading = true
        defer { isLoading = false }
        do {
            try await session.signUp(fullName: fullName, email: email, password: password)
        } catch {
            formError = error.localizedDescription
        }
    }
}

@MainActor
final class PasswordResetViewModel: ObservableObject {
    @Published var email = ""
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    @Published var error: String?
    @Published var successMessage: String?
    @Published var isLoading = false

    func submit(auth: AuthService) async {
        error = nil
        if let emailError = Validators.emailError(email) {
            error = emailError
            return
        }
        isLoading = true
        defer { isLoading = false }

        if auth.supportsDirectPasswordReset {
            if let passwordError = Validators.passwordError(newPassword) {
                error = passwordError
                return
            }
            guard newPassword == confirmPassword else {
                error = "Passwords do not match."
                return
            }
            do {
                try await auth.resetPassword(email: email, newPassword: newPassword)
                successMessage = "Your password has been reset. You can now log in."
            } catch {
                self.error = error.localizedDescription
            }
        } else {
            do {
                try await auth.sendPasswordReset(email: email)
                successMessage = "We sent a password reset link to \(email.trimmed)."
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}
