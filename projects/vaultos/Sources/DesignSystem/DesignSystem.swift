import SwiftUI

// MARK: - Colors
enum AppColors {
    static let accent = Color(hex: "FFD700")
    static let accentSecondary = Color(hex: "F5A623")
    static let background = Color(hex: "0A0A0F")
    static let cardBackground = Color(hex: "141420")
    static let cardBorder = Color.white.opacity(0.08)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.65)
    static let textTertiary = Color.white.opacity(0.4)
    static let success = Color(hex: "34D399")
    static let danger = Color(hex: "EF4444")
    static let warning = Color(hex: "F59E0B")
    static let info = Color(hex: "3B82F6")
    static let goldGradient = LinearGradient(
        colors: [Color(hex: "FFD700"), Color(hex: "F5A623")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Typography
enum AppTypography {
    static let heroTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let pageTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let sectionTitle = Font.system(size: 20, weight: .semibold)
    static let bodyLarge = Font.system(size: 17, weight: .regular)
    static let bodyMedium = Font.system(size: 15, weight: .regular)
    static let caption = Font.system(size: 13, weight: .medium)
    static let mono = Font.system(size: 15, weight: .medium, design: .monospaced)
    static let monoLarge = Font.system(size: 22, weight: .bold, design: .monospaced)
}

// MARK: - Spacing
enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - View Modifiers
struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppSpacing.md)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
    }
}

struct GoldGlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppSpacing.md)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.accent.opacity(0.3), lineWidth: 1)
            )
    }
}

extension View {
    func glassCard() -> some View { modifier(GlassCard()) }
    func goldGlassCard() -> some View { modifier(GoldGlassCard()) }
}

// MARK: - Color Extension
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
