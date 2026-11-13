import SwiftUI

 // MARK: - Primary Button

 struct CKPrimaryButtonStyle: ButtonStyle {

    var height: CGFloat = CKMetrics.buttonHeight

    var fontSize: CGFloat = 15

    func makeBody(configuration: Configuration) -> some View {

        configuration.label

            .font(.system(size: fontSize, weight: .semibold))

            .foregroundStyle(.white)

            .frame(maxWidth: .infinity)

            .frame(height: height)

            .background(

                RoundedRectangle(

                    cornerRadius: CKMetrics.fieldRadius,

                    style: .continuous

                )

                .fill(

                    configuration.isPressed

                    ? CKColor.primaryPressed

                    : CKColor.primary

                )

            )

            .opacity(configuration.isPressed ? 0.9 : 1.0)

            .contentShape(Rectangle())

    }

 }


 // MARK: - Outline Button

 struct CKOutlineButtonStyle: ButtonStyle {

    var height: CGFloat = CKMetrics.buttonHeight

    var fontSize: CGFloat = 15

    func makeBody(configuration: Configuration) -> some View {

        configuration.label

            .font(.system(size: fontSize, weight: .semibold))

            .foregroundStyle(CKColor.primary)

            .frame(maxWidth: .infinity)

            .frame(height: height)

            .background(

                RoundedRectangle(

                    cornerRadius: CKMetrics.fieldRadius,

                    style: .continuous

                )

                .fill(

                    configuration.isPressed

                    ? CKColor.aqua

                    : Color.white

                )

            )

            .overlay(

                RoundedRectangle(

                    cornerRadius: CKMetrics.fieldRadius,

                    style: .continuous

                )

                .stroke(

                    CKColor.primary,

                    lineWidth: 1.2

                )

            )

            .contentShape(Rectangle())

    }

 }


 // MARK: - Compact Button

 // Compact teal button used for headers such as "Add Product"

 struct CKCompactButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {

        configuration.label

            .font(.system(size: 14, weight: .semibold))

            .foregroundStyle(.white)

            .padding(.horizontal, 14)

            .frame(height: 40)

            .background(

                RoundedRectangle(

                    cornerRadius: CKMetrics.fieldRadius,

                    style: .continuous

                )

                .fill(

                    configuration.isPressed

                    ? CKColor.primaryPressed

                    : CKColor.primary

                )

            )

            .contentShape(Rectangle())

    }

 }


 // MARK: - Soft Button

 // Soft aqua pill used for "Edit" actions

 struct CKSoftButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {

        configuration.label

            .font(.system(size: 13, weight: .semibold))

            .foregroundStyle(CKColor.primary)

            .padding(.horizontal, 12)

            .frame(height: 38)

            .background(

                RoundedRectangle(

                    cornerRadius: CKMetrics.fieldRadius,

                    style: .continuous

                )

                .fill(

                    configuration.isPressed

                    ? CKColor.aquaStrong

                    : CKColor.aqua

                )

            )

            .contentShape(Rectangle())

    }

 }


 // MARK: - Small Outline Button

 // Small outlined "Edit" pill used on review cards

 struct CKSmallOutlineButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {

        configuration.label

            .font(.system(size: 12, weight: .semibold))

            .foregroundStyle(CKColor.primary)

            .padding(.horizontal, 12)

            .frame(height: 28)

            .background(

                RoundedRectangle(

                    cornerRadius: 7,

                    style: .continuous

                )

                .fill(

                    configuration.isPressed

                    ? CKColor.aqua

                    : Color.white

                )

            )

            .overlay(

                RoundedRectangle(

                    cornerRadius: 7,

                    style: .continuous

                )

                .stroke(

                    CKColor.primary.opacity(0.7),

                    lineWidth: 1

                )

            )

            .contentShape(Rectangle())

    }

 }


 // MARK: - Button Style Shortcuts

 extension ButtonStyle where Self == CKPrimaryButtonStyle {

    static var ckPrimary: CKPrimaryButtonStyle {

        CKPrimaryButtonStyle()

    }

    static func ckPrimary(

        height: CGFloat,

        fontSize: CGFloat = 15

    ) -> CKPrimaryButtonStyle {

        CKPrimaryButtonStyle(

            height: height,

            fontSize: fontSize

        )

    }

 }


 extension ButtonStyle where Self == CKOutlineButtonStyle {

    static var ckOutline: CKOutlineButtonStyle {

        CKOutlineButtonStyle()

    }

 }


 extension ButtonStyle where Self == CKCompactButtonStyle {

    static var ckCompact: CKCompactButtonStyle {

        CKCompactButtonStyle()

    }

 }


 extension ButtonStyle where Self == CKSoftButtonStyle {

    static var ckSoft: CKSoftButtonStyle {

        CKSoftButtonStyle()

    }

 }


 extension ButtonStyle where Self == CKSmallOutlineButtonStyle {

    static var ckSmallOutline: CKSmallOutlineButtonStyle {

        CKSmallOutlineButtonStyle()

    }

 }


 // MARK: - Back Button

 struct CKBackButton: View {

    let action: () -> Void

    var body: some View {

        Button(action: action) {

            Image(systemName: "arrow.left")

                .font(

                    .system(

                        size: 17,

                        weight: .semibold

                    )

                )

                .foregroundStyle(CKColor.navy)

                .frame(width: 38, height: 38)

                .background(

                    Circle()

                        .fill(CKColor.aqua)

                )

        }

        .buttonStyle(.plain)

        .accessibilityLabel("Back")

    }

 }


 // MARK: - Arrow Label

 // Label + trailing arrow used on Login / Sign Up / Next buttons

 struct CKArrowLabel: View {

    let title: String

    var isLoading: Bool = false

    var body: some View {

        ZStack {

            if isLoading {

                ProgressView()

                    .tint(.white)

            } else {

                Text(title)

            }

            HStack {

                Spacer()

                Image(systemName: "arrow.right")

                    .font(

                        .system(

                            size: 17,

                            weight: .semibold

                        )

                    )

            }

        }

        .padding(.horizontal, 18)

    }

 }


 // MARK: - More Menu Glyph

 // Vertical three-dot menu glyph used on list cards

 struct CKMoreGlyph: View {

    var body: some View {

        Image(systemName: "ellipsis")

            .rotationEffect(.degrees(90))

            .font(

                .system(

                    size: 16,

                    weight: .bold

                )

            )

            .foregroundStyle(CKColor.navy)

            .frame(width: 30, height: 26)

            .contentShape(Rectangle())

    }

 }
