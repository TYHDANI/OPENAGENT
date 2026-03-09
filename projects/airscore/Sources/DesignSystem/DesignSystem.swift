import SwiftUI

enum AppColors {
    static let accent = Color(hex: "4ECDC4")       // Teal
    static let background = Color(hex: "0D1117")
    static let surface = Color(hex: "161B22")
    static let success = Color(hex: "2ECC71")
    static let warning = Color(hex: "F39C12")
    static let danger = Color(hex: "E74C3C")
    static let info = Color(hex: "3498DB")
}

enum AppTypography {
    static let largeTitle = Font.system(size: 34, weight: .bold)
    static let title = Font.system(size: 22, weight: .bold)
    static let headline = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 15)
    static let caption = Font.system(size: 12)
    static let score = Font.system(size: 48, weight: .bold, design: .rounded)
}

enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08)))
    }
}

struct AccentGlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColors.accent.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.accent.opacity(0.3)))
    }
}

extension View {
    func glassCard() -> some View { modifier(GlassCard()) }
    func accentGlassCard() -> some View { modifier(AccentGlassCard()) }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
