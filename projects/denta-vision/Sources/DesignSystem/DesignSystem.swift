import SwiftUI

// MARK: - DentaVision Theme: "Clinical Precision"
// Near-white backgrounds, teal accent, ultra-crisp medical SaaS

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

// MARK: - Colors

enum AppColors {
    static let background = Color(hex: "F8FAFB")
    static let secondaryBackground = Color(hex: "F0F4F6")
    static let groupedBackground = Color(hex: "F8FAFB")
    static let tertiaryBackground = Color(hex: "E8EEF1")
    static let elevatedBackground = Color.white

    static let accent = Color(hex: "0891B2")
    static let accentLight = Color(hex: "0891B2").opacity(0.08)
    static let accentMedium = Color(hex: "0891B2").opacity(0.2)

    static let success = Color(hex: "10B981")
    static let warning = Color(hex: "F59E0B")
    static let error = Color(hex: "EF4444")
    static let info = Color(hex: "0891B2")

    static let textPrimary = Color(hex: "0F172A")
    static let textSecondary = Color(hex: "475569")
    static let textTertiary = Color(hex: "94A3B8")

    static let divider = Color(hex: "E2E8F0")
    static let cardBackground = Color.white
}

// MARK: - Typography

enum AppTypography {
    static let heroTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let pageTitle = Font.system(.title, design: .rounded).weight(.bold)
    static let sectionTitle = Font.system(.title3, design: .rounded).weight(.semibold)
    static let cardTitle = Font.system(.headline, design: .rounded).weight(.semibold)
    static let body = Font.body
    static let bodyBold = Font.body.weight(.semibold)
    static let callout = Font.callout
    static let caption = Font.caption
    static let captionBold = Font.caption.weight(.semibold)
    static let caption2 = Font.caption2
    static let badge = Font.system(.caption2, design: .rounded).weight(.bold)
    static let metric = Font.system(size: 36, weight: .bold, design: .rounded)
    static let metricSmall = Font.system(size: 24, weight: .bold, design: .rounded)
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
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 18
    static let xl: CGFloat = 26
    static let full: CGFloat = 999
}

struct AppShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

enum AppShadow {
    static let sm = AppShadowStyle(color: Color(hex: "0891B2").opacity(0.06), radius: 4, x: 0, y: 2)
    static let md = AppShadowStyle(color: Color(hex: "0891B2").opacity(0.08), radius: 8, x: 0, y: 4)
    static let lg = AppShadowStyle(color: Color(hex: "0891B2").opacity(0.1), radius: 20, x: 0, y: 8)
}

extension View {
    func appShadow(_ style: AppShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}

enum AppAnimation {
    static let springBounce = Animation.spring(response: 0.4, dampingFraction: 0.75)
    static let springSnappy = Animation.spring(response: 0.3, dampingFraction: 0.85)
    static let easeSmooth = Animation.easeInOut(duration: 0.25)
    static let easeSlow = Animation.easeInOut(duration: 0.5)
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
            colors: [Color(hex: "0891B2").opacity(opacity), Color(hex: "06B6D4").opacity(opacity * 0.8)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    static func glass() -> some ShapeStyle { .ultraThinMaterial }
}
