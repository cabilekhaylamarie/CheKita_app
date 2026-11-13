import SwiftUI

/// Switches between Splash → Onboarding → Auth → Main based on the session stage.
struct RootView: View {
    @EnvironmentObject private var session: SessionViewModel
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        ZStack {
            switch session.stage {
            case .splash:
                SplashView()
                    .transition(.opacity)
            case .onboarding:
                OnboardingView()
                    .transition(.opacity)
            case .auth:
                AuthFlowView()
                    .transition(.opacity)
            case .main:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: session.stage)
        .task(id: session.currentUser?.id) {
            if let id = session.currentUser?.id {
                await store.configure(userID: id)
            } else {
                store.reset()
                router.reset()
            }
        }
    }
}

struct AuthFlowView: View {
    @EnvironmentObject private var session: SessionViewModel

    var body: some View {
        ZStack {
            switch session.authScreen {
            case .login:
                LoginView()
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
            case .signUp:
                SignUpView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: session.authScreen)
    }
}
