import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var session: SessionViewModel
    @StateObject private var vm = SignUpViewModel()
    @State private var legalDocument: LegalDocument? = nil
    @FocusState private var focus: Field?

    private enum Field { case name, email, password, confirm }

    var body: some View {
        ZStack {
            CKAuthBackground()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        backToLogin()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(CKColor.navy)
                            .frame(width: 40, height: 40)
                    }
                    .accessibilityLabel("Back to login")
                    Spacer()
                    Button("Login", action: backToLogin)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(CKColor.primary)
                }
                .padding(.horizontal, 14)
                .padding(.top, 4)

                ScrollView {
                    VStack(spacing: 0) {
                        AuthBrandHeader(logoHeight: 86, taglineSize: 13)

                        VStack(spacing: 5) {
                            Text("Create an Account")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(CKColor.navy)
                            Text("Start managing your business easily with CheKita.")
                                .font(.system(size: 14))
                                .foregroundStyle(CKColor.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 16)

                        fields
                            .padding(.top, 18)

                        termsRow
                            .padding(.top, 14)

                        if let error = vm.formError {
                            CKErrorText(message: error)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 8)
                        }

                        Button(action: signUp) {
                            CKArrowLabel(title: "Sign Up", isLoading: vm.isLoading)
                        }
                        .buttonStyle(.ckPrimary)
                        .disabled(vm.isLoading)
                        .padding(.top, 16)

                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundStyle(CKColor.navy)
                            Button("Login", action: backToLogin)
                                .fontWeight(.semibold)
                                .foregroundStyle(CKColor.primary)
                        }
                        .font(.system(size: 14))
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 24)
                    .frame(maxWidth: 500)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .sheet(item: $legalDocument) { document in
            NavigationStack {
                LegalDocumentView(document: document, showsBackButton: false)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { legalDocument = nil }
                        }
                    }
            }
        }
    }

    private var fields: some View {
        VStack(spacing: 12) {
            CKTextField(icon: "person", placeholder: "Full Name", text: $vm.fullName,
                        contentType: .name, capitalization: .words, errorMessage: vm.fullNameError)
                .focused($focus, equals: .name)
                .submitLabel(.next)
                .onSubmit { focus = .email }
            CKTextField(icon: "envelope", placeholder: "Email address", text: $vm.email,
                        keyboard: .emailAddress, contentType: .emailAddress, capitalization: .never,
                        errorMessage: vm.emailError)
                .focused($focus, equals: .email)
                .submitLabel(.next)
                .onSubmit { focus = .password }
            CKTextField(icon: "lock", placeholder: "Password", text: $vm.password, isSecure: true,
                        contentType: .newPassword, errorMessage: vm.passwordError)
                .focused($focus, equals: .password)
                .submitLabel(.next)
                .onSubmit { focus = .confirm }
            CKTextField(icon: "lock", placeholder: "Confirm Password", text: $vm.confirmPassword, isSecure: true,
                        contentType: .newPassword, errorMessage: vm.confirmError)
                .focused($focus, equals: .confirm)
                .submitLabel(.go)
                .onSubmit(signUp)
        }
    }

    private var termsRow: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .top, spacing: 10) {
                Button {
                    vm.agreedToTerms.toggle()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(vm.termsError == nil ? (vm.agreedToTerms ? CKColor.primary : CKColor.fieldBorder) : CKColor.danger,
                                    lineWidth: 1.5)
                        if vm.agreedToTerms {
                            Circle().fill(CKColor.primary).padding(4)
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("I agree to the Terms and Conditions and Privacy Policy")
                .accessibilityAddTraits(vm.agreedToTerms ? .isSelected : [])

                Text("I agree to the [Terms and Conditions](chekita://terms) and [Privacy Policy](chekita://privacy)")
                    .font(.system(size: 13))
                    .foregroundStyle(CKColor.navy)
                    .tint(CKColor.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .environment(\.openURL, OpenURLAction { url in
                        legalDocument = url.host == "privacy" ? .privacy : .terms
                        return .handled
                    })
                    .onTapGesture { vm.agreedToTerms.toggle() }
                Spacer(minLength: 0)
            }
            if let error = vm.termsError {
                CKErrorText(message: error)
            }
        }
    }

    private func signUp() {
        Keyboard.dismiss()
        Task { await vm.signUp(session: session) }
    }

    private func backToLogin() {
        Keyboard.dismiss()
        session.authScreen = .login
    }
}
