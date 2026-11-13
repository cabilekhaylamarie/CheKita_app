import Foundation

enum Validators {
    static let minPasswordLength = 6

    static func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return email.trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    static func emailError(_ email: String) -> String? {
        if email.trimmed.isEmpty { return "Email address is required." }
        if !isValidEmail(email) { return "Enter a valid email address." }
        return nil
    }

    static func passwordError(_ password: String) -> String? {
        if password.isEmpty { return "Password is required." }
        if password.count < minPasswordLength { return "Password must be at least \(minPasswordLength) characters." }
        return nil
    }
}
