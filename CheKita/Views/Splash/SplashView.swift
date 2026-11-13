import SwiftUI

/// Uses the provided `splashscreen.png` artwork (logo, tagline, loading bar) full-screen,
/// then advances to Onboarding (or straight to Home when a session exists).
struct SplashView: View {
    @EnvironmentObject private var session: SessionViewModel
    @State private var appeared = false

    var body: some View {
        GeometryReader { proxy in
            Image("splashscreen")
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .scaleEffect(appeared ? 1 : 1.03)
                .opacity(appeared ? 1 : 0.6)
        }
        .ignoresSafeArea()
        .background(Color.white.ignoresSafeArea())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("CheKita. Small Business Costing and Profit Analyzer. Loading.")
        .task {
            withAnimation(.easeOut(duration: 0.8)) { appeared = true }
            try? await Task.sleep(nanoseconds: 2_300_000_000)
            await session.finishSplash()
        }
    }
}
