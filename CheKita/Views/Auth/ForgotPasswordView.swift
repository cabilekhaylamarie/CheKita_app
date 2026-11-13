import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject private var session: SessionViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = PasswordResetViewModel()
    let prefilledEmail: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 30))
                        .foregroundStyle(CKColor.primary)
                        .frame(width: 64, height: 64)
                        .background(Circle().fill(CKColor.aqua))
                        .frame(maxWidth: .infinity)

                    Text(session.auth.supportsDirectPasswordReset
                         ? "Enter the email you signed up with and choose a new password."
                         : "Enter the email you signed up with and we'll send you a reset link.")
                        .font(.system(size: 14))
                        .foregroundStyle(CKColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 6) {
                        CKFieldLabel("Email Address", required: true)
                        CKTextField(icon: "envelope", placeholder: "Email address", text: $vm.email,
                                    keyboard: .emailAddress, contentType: .emailAddress, capitalization: .never)
                    }

                    if session.auth.supportsDirectPasswordReset {
                        VStack(alignment: .leading, spacing: 6) {
                            CKFieldLabel("New Password", required: true)
                            CKTextField(icon: "lock", placeholder: "New password", text: $vm.newPassword,
                                        isSecure: true, contentType: .newPassword)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            CKFieldLabel("Confirm New Password", required: true)
                            CKTextField(icon: "lock", placeholder: "Confirm new password", text: $vm.confirmPassword,
                                        isSecure: true, contentType: .newPassword)
                        }
                    }

                    if let error = vm.error {
                        CKErrorText(message: error)
                    }

                    if let success = vm.successMessage {
                        Label(success, systemImage: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(CKColor.primary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 10).fill(CKColor.aqua))
                        Button("Back to Login") { dismiss() }
                            .buttonStyle(.ckPrimary)
                    } else {
                        Button {
                            Keyboard.dismiss()
                            Task { await vm.submit(auth: session.auth) }
                        } label: {
                            if vm.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(session.auth.supportsDirectPasswordReset ? "Reset Password" : "Send Reset Link")
                            }
                        }
                        .buttonStyle(.ckPrimary)
                        .disabled(vm.isLoading)
                    }
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            if vm.email.isEmpty { vm.email = prefilledEmail }
        }
    }
}
