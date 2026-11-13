import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: SessionViewModel
    @EnvironmentObject private var router: AppRouter
    @State private var showLogoutConfirm = false
    @State private var avatarData: Data? = nil
    @State private var isUploadingAvatar = false
    @State private var avatarError: String? = nil

    private var user: AppUser? { session.currentUser }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    CKScreenHeader(title: "Profile", subtitle: "Manage your account and preferences.")
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                        .foregroundStyle(CKColor.primaryLight)
                        .padding(.top, 4)
                        .accessibilityHidden(true)
                }
                .padding(.top, 12)

                profileCard

                ProfileSection(title: "Account Information") {
                    ProfileRow(icon: "person", title: "Full Name", subtitle: user?.fullName ?? "—") { router.push(.editProfile, in: .profile) }
                    ProfileRow(icon: "envelope", title: "Email Address", subtitle: user?.email ?? "—") { router.push(.editProfile, in: .profile) }
                    ProfileRow(icon: "storefront", title: "Business Name",
                               subtitle: (user?.businessName.isEmpty ?? true) ? "Add your business name" : user!.businessName,
                               isLast: true) { router.push(.editProfile, in: .profile) }
                }

                ProfileSection(title: "Settings") {
                    ProfileRow(icon: "bell", title: "Notifications", subtitle: "Manage your notification preferences") { router.push(.notifications, in: .profile) }
                    ProfileRow(icon: "lock", title: "Change Password", subtitle: "Update your password") { router.push(.changePassword, in: .profile) }
                    ProfileRow(icon: "gearshape", title: "App Settings", subtitle: "Data, currency and more", isLast: true) { router.push(.appSettings, in: .profile) }
                }

                ProfileSection(title: "About") {
                    ProfileRow(icon: "info.circle", title: "About CheKita", subtitle: "Version \(AppInfo.version)") { router.push(.about, in: .profile) }
                    ProfileRow(icon: "doc.text", title: "Terms & Conditions", subtitle: "Read our terms and conditions") { router.push(.legal(.terms), in: .profile) }
                    ProfileRow(icon: "shield", title: "Privacy Policy", subtitle: "Read our privacy policy", isLast: true) { router.push(.legal(.privacy), in: .profile) }
                }

                Button {
                    showLogoutConfirm = true
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .buttonStyle(.ckPrimary)
                .padding(.top, 4)
            }
            .padding(.horizontal, CKMetrics.hPadding)
            .padding(.bottom, 20)
        }
        .ckScreenBackground(waveHeight: 110)
        .alert("Log Out?", isPresented: $showLogoutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) { session.signOut() }
        } message: {
            Text("You can log back in anytime with your email and password.")
        }
        .onChange(of: avatarData) { _, data in
            guard let data else { return }
            isUploadingAvatar = true
            Task {
                do {
                    try await session.updateAvatar(imageData: data)
                } catch {
                    avatarError = error.localizedDescription
                }
                isUploadingAvatar = false
                avatarData = nil
            }
        }
        .alert("Photo not updated", isPresented: Binding(get: { avatarError != nil }, set: { if !$0 { avatarError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(avatarError ?? "")
        }
    }

    private var profileCard: some View {
        HStack(spacing: 14) {
            CKPhotoPicker(data: $avatarData) {
                ZStack(alignment: .bottomTrailing) {
                    CKAvatar(fileName: user?.avatarFileName, base64: user?.avatarData,
                             cacheKey: "avatar-\(user?.id ?? "")", size: 72)
                        .overlay {
                            if isUploadingAvatar {
                                ZStack {
                                    Circle().fill(Color.black.opacity(0.35))
                                    ProgressView().tint(.white)
                                }
                            }
                        }
                    Image(systemName: "camera.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(CKColor.primary))
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
            }
            .disabled(isUploadingAvatar)
            .accessibilityLabel("Change profile photo")

            VStack(alignment: .leading, spacing: 3) {
                Text("Hi, \(user?.firstName ?? "User")!")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(CKColor.navy)
                Text(user?.email ?? "")
                    .font(.system(size: 13))
                    .foregroundStyle(CKColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Button {
                    router.push(.editProfile, in: .profile)
                } label: {
                    Label("Edit Profile", systemImage: "pencil")
                }
                .buttonStyle(CKSmallOutlineButtonStyle())
                .padding(.top, 4)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(CKColor.aqua))
    }
}

enum AppInfo {
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

struct ProfileSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(CKColor.navy)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CKColor.aquaSoft)
            content()
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: CKMetrics.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: CKMetrics.cardRadius, style: .continuous).stroke(CKColor.border, lineWidth: 1))
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var isLast = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(CKColor.primary)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(CKColor.aqua))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(CKColor.navy)
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(CKColor.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CKColor.navy)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                if !isLast {
                    Divider().overlay(CKColor.border).padding(.leading, 58)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
