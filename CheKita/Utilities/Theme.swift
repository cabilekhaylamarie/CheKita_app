import SwiftUI
import UIKit

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

/// CheKita design tokens, sampled from the provided screens.
enum CKColor {
    static let primary = Color(hex: 0x0E7C86)
    static let primaryPressed = Color(hex: 0x0A646C)
    static let primaryLight = Color(hex: 0x2AA6A6)
    static let navy = Color(hex: 0x0D2B3E)
    static let textSecondary = Color(hex: 0x5E6E7A)
    static let textTertiary = Color(hex: 0x98A6B0)
    static let aqua = Color(hex: 0xE3F4F3)
    static let aquaStrong = Color(hex: 0xCDEBE8)
    static let aquaSoft = Color(hex: 0xF1F9F9)
    static let background = Color(hex: 0xF7FBFB)
    static let border = Color(hex: 0xE2EAEE)
    static let fieldBorder = Color(hex: 0xD6E0E5)
    static let fieldFill = Color(hex: 0xF4F8F9)
    static let pill = Color(hex: 0xEEF3F5)
    static let danger = Color(hex: 0xD9534F)
    static let dangerSoft = Color(hex: 0xFDECEC)
    static let warning = Color(hex: 0xB7791F)
    static let warningSoft = Color(hex: 0xFFF6E5)

    static let uiPrimary = UIColor(red: 14 / 255, green: 124 / 255, blue: 134 / 255, alpha: 1)
    static let uiNavy = UIColor(red: 13 / 255, green: 43 / 255, blue: 62 / 255, alpha: 1)
    static let uiSecondary = UIColor(red: 94 / 255, green: 110 / 255, blue: 122 / 255, alpha: 1)
    static let uiAqua = UIColor(red: 227 / 255, green: 244 / 255, blue: 243 / 255, alpha: 1)
    static let uiBorder = UIColor(red: 226 / 255, green: 234 / 255, blue: 238 / 255, alpha: 1)
}

enum CKMetrics {
    static let hPadding: CGFloat = 16
    static let cardRadius: CGFloat = 12
    static let fieldRadius: CGFloat = 10
    static let buttonHeight: CGFloat = 50
    static let fieldHeight: CGFloat = 48
}

struct CKCardModifier: ViewModifier {
    var padding: CGFloat
    var radius: CGFloat
    var fill: Color

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(CKColor.border, lineWidth: 1))
            .shadow(color: CKColor.navy.opacity(0.045), radius: 8, x: 0, y: 3)
    }
}

extension View {
    func ckCard(padding: CGFloat = 12, radius: CGFloat = CKMetrics.cardRadius, fill: Color = .white) -> some View {
        modifier(CKCardModifier(padding: padding, radius: radius, fill: fill))
    }

    /// Transparent, separator-less List row with CheKita card spacing.
    func ckListRow(top: CGFloat = 5, bottom: CGFloat = 5) -> some View {
        self
            .listRowInsets(EdgeInsets(top: top, leading: CKMetrics.hPadding, bottom: bottom, trailing: CKMetrics.hPadding))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

enum Keyboard {
    static func dismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

// MARK: - Category tints (soft badge colors seen in the screenshots)

extension ProductCategory {
    var badgeBackground: Color {
        switch self {
        case .cookies: return Color(hex: 0xE2F1F6)
        case .cakes: return Color(hex: 0xFCE9EC)
        case .pastries: return Color(hex: 0xEDEBFA)
        case .breads: return Color(hex: 0xE4F4E9)
        case .desserts: return Color(hex: 0xECE7F9)
        case .drinks: return Color(hex: 0xFBEFE4)
        case .others: return Color(hex: 0xE3F4F3)
        }
    }

    var badgeForeground: Color {
        switch self {
        case .cookies: return Color(hex: 0x2C6E86)
        case .cakes: return Color(hex: 0xA9475C)
        case .pastries: return Color(hex: 0x6557A8)
        case .breads: return Color(hex: 0x2E7D4B)
        case .desserts: return Color(hex: 0x6A4FB0)
        case .drinks: return Color(hex: 0xA5642B)
        case .others: return CKColor.primary
        }
    }
}

extension MaterialCategory {
    var badgeBackground: Color {
        switch self {
        case .dryGoods: return Color(hex: 0xE6F0FA)
        case .dairy: return Color(hex: 0xE3F4F3)
        case .packaging: return Color(hex: 0xFBF1E3)
        case .others: return Color(hex: 0xEDEBFA)
        }
    }

    var badgeForeground: Color {
        switch self {
        case .dryGoods: return Color(hex: 0x3566A0)
        case .dairy: return CKColor.primary
        case .packaging: return Color(hex: 0x9E6420)
        case .others: return Color(hex: 0x6557A8)
        }
    }
}
