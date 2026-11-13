import SwiftUI
import UserNotifications

// MARK: - Edit Profile

struct EditProfileView: View {
    @EnvironmentObject private var session: SessionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var businessName = ""
    @State private var avatarData: Data? = nil
    @State private var removeAvatar = false
    @State private var nameError: String? = nil
    @State private var formError: String? = nil
    @State private var isSaving = false
    @State private var loaded = false

    private var previewImage: UIImage? {
        if let avatarData { return UIImage(data: avatarData) }
        if removeAvatar { return nil }
        let user = session.currentUser
        return ImageStore.shared.image(named: user?.avatarFileName)
            ?? ImageStore.shared.image(base64: user?.avatarData, cacheKey: "avatar-\(user?.id ?? "")")
    }

    var body: some View {
        VStack(spacing: 0) {
            CKNavHeader(title: "Edit Profile", subtitle: "Update your account details.", onBack: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(spacing: 8) {
                        CKPhotoPicker(data: $avatarData) {
                            ZStack(alignment: .bottomTrailing) {
                                Group {
                                    if let previewImage {
                                        Image(uiImage: previewImage).resizable().scaledToFill()
                                    } else {
                                        CKAvatar(fileName: nil, size: 92)
                                    }
                                }
                                .frame(width: 92, height: 92)
                                .clipShape(Circle())
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white)
                                    .frame(width: 30, height: 30)
                                    .background(Circle().fill(CKColor.primary))
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            }
                        }
                        .accessibilityLabel("Change profile photo")
                        if previewImage != nil {
                            Button("Remove Photo") {
                                avatarData = nil
                                removeAvatar = true
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(CKColor.danger)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .onChange(of: avatarData) { _, data in if data != nil { removeAvatar = false } }

                    VStack(alignment: .leading, spacing: 6) {
                        CKFieldLabel("Full Name", required: true)
                        CKTextField(icon: "person", placeholder: "Full Name", text: $fullName,
                                    contentType: .name, capitalization: .words, errorMessage: nameError)
                            .onChange(of: fullName) { _, _ in nameError = nil }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        CKFieldLabel("Email Address")
                        HStack(spacing: 12) {
                            Image(systemName: "envelope").foregroundStyle(CKColor.textSecondary).frame(width: 22)
                            Text(session.currentUser?.email ?? "")
                                .font(.system(size: 15))
                                .foregroundStyle(CKColor.textSecondary)
                            Spacer()
                            Image(systemName: "lock.fill").font(.system(size: 12)).foregroundStyle(CKColor.textTertiary)
                        }
                        .padding(.horizontal, 14)
                        .frame(height: CKMetrics.fieldHeight)
                        .background(RoundedRectangle(cornerRadius: CKMetrics.fieldRadius).fill(CKColor.fieldFill))
                        .overlay(RoundedRectangle(cornerRadius: CKMetrics.fieldRadius).stroke(CKColor.border, lineWidth: 1))
                        Text("Your email is used to log in and can't be changed here.")
                            .font(.system(size: 11))
                            .foregroundStyle(CKColor.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        CKFieldLabel("Business Name")
                        CKTextField(icon: "storefront", placeholder: "e.g. Sweet Bites Bakery", text: $businessName,
                                    contentType: .organizationName, capitalization: .words)
                    }

                    if let formError { CKErrorText(message: formError) }
                }
                .padding(.horizontal, CKMetrics.hPadding)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                CKBottomBar {
                    HStack(spacing: 10) {
                        Button("Cancel") { dismiss() }.buttonStyle(.ckOutline)
                        Button {
                            save()
                        } label: {
                            if isSaving { ProgressView().tint(.white) } else { Text("Save Changes") }
                        }
                        .buttonStyle(.ckPrimary)
                        .disabled(isSaving)
                    }
                }
            }
        }
        .ckScreenBackground(waveHeight: 100)
        .onAppear {
            guard !loaded, let user = session.currentUser else { return }
            loaded = true
            fullName = user.fullName
            businessName = user.businessName
        }
    }

    private func save() {
        Keyboard.dismiss()
        guard var user = session.currentUser else { return }
        guard !fullName.trimmed.isEmpty else {
            nameError = "Full name is required."
            return
        }
        user.fullName = fullName.trimmed
        user.businessName = businessName.trimmed
        // nil = photo unchanged, .some(data) = new photo, .some(nil) = remove photo.
        var photoChange: Data?? = nil
        if let avatarData {
            photoChange = .some(avatarData)
        } else if removeAvatar {
            photoChange = .some(nil)
        }

        isSaving = true
        formError = nil
        Task {
            defer { isSaving = false }
            do {
                try await session.updateProfile(user)
                if let photoChange {
                    try await session.updateAvatar(imageData: photoChange)
                }
                dismiss()
            } catch {
                formError = error.localizedDescription
            }
        }
    }
}

// MARK: - Change Password

struct ChangePasswordView: View {
    @EnvironmentObject private var session: SessionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var current = ""
    @State private var newPassword = ""
    @State private var confirm = ""
    @State private var currentError: String? = nil
    @State private var newError: String? = nil
    @State private var confirmError: String? = nil
    @State private var formError: String? = nil
    @State private var isSaving = false
    @State private var showSuccess = false

    var body: some View {
        VStack(spacing: 0) {
            CKNavHeader(title: "Change Password", subtitle: "Keep your account secure.", onBack: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        CKFieldLabel("Current Password", required: true)
                        CKTextField(icon: "lock", placeholder: "Current password", text: $current, isSecure: true,
                                    contentType: .password, errorMessage: currentError)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        CKFieldLabel("New Password", required: true)
                        CKTextField(icon: "lock", placeholder: "At least \(Validators.minPasswordLength) characters", text: $newPassword,
                                    isSecure: true, contentType: .newPassword, errorMessage: newError)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        CKFieldLabel("Confirm New Password", required: true)
                        CKTextField(icon: "lock", placeholder: "Re-enter new password", text: $confirm, isSecure: true,
                                    contentType: .newPassword, errorMessage: confirmError)
                    }
                    if let formError { CKErrorText(message: formError) }

                    Button {
                        save()
                    } label: {
                        if isSaving { ProgressView().tint(.white) } else { Text("Update Password") }
                    }
                    .buttonStyle(.ckPrimary)
                    .disabled(isSaving)
                    .padding(.top, 6)
                }
                .padding(.horizontal, CKMetrics.hPadding)
                .padding(.top, 8)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .ckScreenBackground(waveHeight: 100)
        .onChange(of: current) { _, _ in currentError = nil; formError = nil }
        .onChange(of: newPassword) { _, _ in newError = nil; formError = nil }
        .onChange(of: confirm) { _, _ in confirmError = nil; formError = nil }
        .alert("Password Updated", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your password has been changed successfully.")
        }
    }

    private func save() {
        Keyboard.dismiss()
        currentError = current.isEmpty ? "Current password is required." : nil
        newError = Validators.passwordError(newPassword)
        if newError == nil && newPassword == current { newError = "Choose a password different from your current one." }
        confirmError = confirm.isEmpty ? "Please confirm your new password." : (confirm != newPassword ? "Passwords do not match." : nil)
        guard currentError == nil, newError == nil, confirmError == nil else { return }

        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                try await session.auth.changePassword(currentPassword: current, newPassword: newPassword)
                showSuccess = true
            } catch AuthError.wrongCurrentPassword {
                currentError = AuthError.wrongCurrentPassword.errorDescription
            } catch {
                formError = error.localizedDescription
            }
        }
    }
}

// MARK: - Notifications

struct NotificationSettingsView: View {
    @EnvironmentObject private var session: SessionViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("chekita.notify.lowStock") private var lowStockAlerts = true
    @AppStorage("chekita.notify.production") private var productionReminders = false
    @State private var enabled = true
    @State private var permissionDenied = false

    var body: some View {
        VStack(spacing: 0) {
            CKNavHeader(title: "Notifications", subtitle: "Manage your notification preferences.", onBack: { dismiss() })
            ScrollView {
                VStack(spacing: 12) {
                    toggleCard(title: "Allow Notifications", subtitle: "Turn all CheKita notifications on or off.",
                               isOn: Binding(get: { enabled }, set: { setEnabled($0) }))
                    toggleCard(title: "Low Stock Alerts", subtitle: "Get notified when a material runs low.", isOn: $lowStockAlerts)
                        .disabled(!enabled)
                        .opacity(enabled ? 1 : 0.5)
                    toggleCard(title: "Production Reminders", subtitle: "Reminders to record finished batches.", isOn: $productionReminders)
                        .disabled(!enabled)
                        .opacity(enabled ? 1 : 0.5)
                    if permissionDenied {
                        Label("Notifications are turned off for CheKita in iOS Settings.", systemImage: "exclamationmark.triangle")
                            .font(.system(size: 12))
                            .foregroundStyle(CKColor.warning)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, CKMetrics.hPadding)
                .padding(.top, 8)
            }
        }
        .ckScreenBackground(waveHeight: 100)
        .onAppear { enabled = session.currentUser?.notificationsEnabled ?? true }
    }

    private func toggleCard(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(CKColor.navy)
                Text(subtitle).font(.system(size: 12)).foregroundStyle(CKColor.textSecondary)
            }
        }
        .tint(CKColor.primary)
        .ckCard(padding: 14)
    }

    private func setEnabled(_ value: Bool) {
        enabled = value
        Task {
            if value {
                let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])) ?? false
                permissionDenied = !granted
            } else {
                permissionDenied = false
            }
            if var user = session.currentUser {
                user.notificationsEnabled = value
                try? await session.updateProfile(user)
            }
        }
    }
}
