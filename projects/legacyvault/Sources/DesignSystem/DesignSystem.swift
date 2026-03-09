import SwiftUI

// MARK: - LegacyVault Theme: "Heritage Gold"
// Deep black backgrounds, gold accent, Swiss bank vault aesthetic

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6: (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8: (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default: (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

enum AppColors {
    static let background = Color(hex: "0C0C0C")
    static let secondaryBackground = Color(hex: "141414")
    static let groupedBackground = Color(hex: "0C0C0C")
    static let tertiaryBackground = Color(hex: "1C1C1C")
    static let elevatedBackground = Color(hex: "262626")

    static let accent = Color(hex: "C9A84C")
    static let accentLight = Color(hex: "C9A84C").opacity(0.1)
    static let accentMedium = Color(hex: "C9A84C").opacity(0.25)

    static let success = Color(hex: "4CAF50")
    static let warning = Color(hex: "E8A838")
    static let error = Color(hex: "D32F2F")
    static let info = Color(hex: "5C9CE6")

    static let textPrimary = Color(hex: "F0ECE0")
    static let textSecondary = Color(hex: "9C9484")
    static let textTertiary = Color(hex: "6A6258")

    static let divider = Color(hex: "2A2620")
    static let cardBackground = Color(hex: "161412")
}

enum AppTypography {
    static let heroTitle = Font.system(.largeTitle, design: .serif).weight(.bold)
    static let pageTitle = Font.system(.title, design: .serif).weight(.bold)
    static let sectionTitle = Font.system(.title3, design: .serif).weight(.semibold)
    static let cardTitle = Font.system(.headline, design: .default).weight(.semibold)
    static let body = Font.body
    static let bodyBold = Font.body.weight(.semibold)
    static let callout = Font.callout
    static let caption = Font.caption
    static let captionBold = Font.caption.weight(.semibold)
    static let caption2 = Font.caption2
    static let badge = Font.system(.caption2, design: .default).weight(.bold)
    static let metric = Font.system(size: 36, weight: .bold, design: .serif)
    static let metricSmall = Font.system(size: 24, weight: .bold, design: .serif)
}

enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum AppRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 10
    static let lg: CGFloat = 14
    static let xl: CGFloat = 20
    static let full: CGFloat = 999
}

struct AppShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

enum AppShadow {
    static let sm = AppShadowStyle(color: Color(hex: "C9A84C").opacity(0.06), radius: 4, x: 0, y: 2)
    static let md = AppShadowStyle(color: Color(hex: "C9A84C").opacity(0.1), radius: 10, x: 0, y: 4)
    static let lg = AppShadowStyle(color: Color(hex: "C9A84C").opacity(0.15), radius: 20, x: 0, y: 8)
}

extension View {
    func appShadow(_ style: AppShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}

enum AppAnimation {
    static let springBounce = Animation.spring(response: 0.5, dampingFraction: 0.7)
    static let springSnappy = Animation.spring(response: 0.3, dampingFraction: 0.85)
    static let easeSmooth = Animation.easeInOut(duration: 0.3)
    static let easeSlow = Animation.easeInOut(duration: 0.6)
}

#if canImport(UIKit)
import UIKit
enum AppHaptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
}
#else
enum AppHaptics {
    static func impact(_ style: Any? = nil) {}
    static func success() {}
    static func warning() {}
    static func error() {}
    static func selection() {}
}
#endif

enum AppGradient {
    static func accent(opacity: CGFloat = 1.0) -> LinearGradient {
        LinearGradient(
            colors: [Color(hex: "C9A84C").opacity(opacity), Color(hex: "A08030").opacity(opacity * 0.7)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    static func glass() -> some ShapeStyle { .ultraThinMaterial }
    static func goldSheen() -> LinearGradient {
        LinearGradient(
            colors: [Color(hex: "C9A84C").opacity(0.1), Color(hex: "C9A84C").opacity(0.02), .clear],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}
