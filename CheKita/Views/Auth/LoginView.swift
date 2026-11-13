import SwiftUI

struct AuthBrandHeader: View {
    var logoHeight: CGFloat = 118
    var taglineSize: CGFloat = 15

    var body: some View {
        VStack(spacing: 4) {
            Image("chekitaapp_logo")
                .resizable()
                .scaledToFit()
                .frame(height: logoHeight)
                .accessibilityLabel("CheKita")
            Text("Small Business Costing\nand Profit Analyzer")
                .font(.system(size: taglineSize))
                .foregroundStyle(CKColor.navy)
                .multilineTextAlignment(.center)
        }
    }
}

struct LoginView: View {
    @EnvironmentObject private var session: SessionViewModel
    @StateObject private var vm = LoginViewModel()
    @State private var showForgotPassword = false
    @FocusState private var focus: Field?

    private enum Field { case email, password }

    var body: some View {
        ZStack {
            CKAuthBackground()

            ScrollView {
                VStack(spacing: 0) {
                    AuthBrandHeader()
                        .padding(.top, 56)

                    VStack(spacing: 4) {
                        Text("Welcome Back!")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(CKColor.navy)
                        Text("Sign in to continue")
                            .font(.system(size: 15))
                            .foregroundStyle(CKColor.textSecondary)
                    }
                    .padding(.top, 22)

                    VStack(spacing: 14) {
                        CKTextField(icon: "envelope", placeholder: "Email address", text: $vm.email,
                                    keyboard: .emailAddress, contentType: .emailAddress, capitalization: .never,
                                    errorMessage: vm.emailError)
                            .focused($focus, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focus = .password }

                        CKTextField(icon: "lock", placeholder: "Password", text: $vm.password, isSecure: true,
                                    contentType: .password, errorMessage: vm.passwordError)
                            .focused($focus, equals: .password)
                            .submitLabel(.go)
                            .onSubmit(login)
                    }
                    .padding(.top, 20)

                    HStack {
                        Spacer()
                        Button("Forgot password?") { showForgotPassword = true }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(CKColor.primary)
                    }
                    .padding(.top, 10)

                    if let error = vm.formError {
                        CKErrorText(message: error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                    }

                    Button(action: login) {
                        CKArrowLabel(title: "Login", isLoading: vm.isLoading)
                    }
                    .buttonStyle(.ckPrimary)
                    .disabled(vm.isLoading)
                    .padding(.top, 16)

                    HStack(spacing: 10) {
                        Rectangle().fill(CKColor.fieldBorder).frame(height: 1)
                        Text("or")
                            .font(.system(size: 13))
                            .foregroundStyle(CKColor.textSecondary)
                        Rectangle().fill(CKColor.fieldBorder).frame(height: 1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 16)

                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundStyle(CKColor.navy)
                        Button("Sign Up") {
                            Keyboard.dismiss()
                            session.authScreen = .signUp
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(CKColor.primary)
                    }
                    .font(.system(size: 14))
                    .padding(.top, 14)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 500)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(prefilledEmail: vm.email)
                .environmentObject(session)
        }
    }

    private func login() {
        Keyboard.dismiss()
        Task { await vm.login(session: session) }
    }
}
