import SwiftUI

/// Single onboarding page built around the provided `chekita_onboard.png` illustration.
struct OnboardingView: View {
    @EnvironmentObject private var session: SessionViewModel

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 2) {
                    Image("chekitaapp_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 58)
                    Text("Small Business Costing\nand Profit Analyzer")
                        .font(.system(size: 9, weight: .regular))
                        .foregroundStyle(CKColor.navy)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                Button("Skip") { session.completeOnboarding() }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(CKColor.primary)
                    .padding(.trailing, 20)
                    .padding(.top, 2)
            }
            .padding(.top, 8)

            // Illustration (includes "Plan Smarter / Sell Better" and the supporting copy).
            Image("chekita_onboard")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 8)
                .accessibilityLabel("Plan Smarter, Sell Better. Track your materials, compute costs, and grow your business.")

            ZStack {
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index == 0 ? CKColor.primary : CKColor.aquaStrong)
                            .frame(width: 9, height: 9)
                    }
                }
                .accessibilityHidden(true)

                HStack {
                    Spacer()
                    Button {
                        session.completeOnboarding()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(Circle().fill(CKColor.primary))
                            .shadow(color: CKColor.primary.opacity(0.3), radius: 6, y: 3)
                    }
                    .accessibilityLabel("Continue")
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(Color.white.ignoresSafeArea())
    }
}
