import Foundation

struct AppUser: Identifiable, Codable, Hashable {
    var id: String
    var fullName: String
    var email: String
    var businessName: String
    var avatarFileName: String?
    /// Small JPEG thumbnail (base64) of the profile photo, saved on the user document.
    var avatarData: String? = nil
    var notificationsEnabled: Bool
    var createdAt: Date

    init(id: String, fullName: String, email: String, businessName: String = "",
         avatarFileName: String? = nil, notificationsEnabled: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.businessName = businessName
        self.avatarFileName = avatarFileName
        self.notificationsEnabled = notificationsEnabled
        self.createdAt = createdAt
    }

    var firstName: String {
        let first = fullName.split(separator: " ").first.map(String.init) ?? ""
        return first.isEmpty ? "User" : first
    }
}
