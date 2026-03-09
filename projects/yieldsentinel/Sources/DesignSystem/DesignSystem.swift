import SwiftUI

// MARK: - YieldSentinel Theme: "AETHER Terminal"
// Pure black backgrounds, neon cyan accent, cyberpunk risk dashboard

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
    static let background = Color(hex: "07070D")
    static let secondaryBackground = Color(hex: "0C0C15")
    static let groupedBackground = Color(hex: "07070D")
    static let tertiaryBackground = Color(hex: "12121F")
    static let elevatedBackground = Color(hex: "1A1A2C")

    static let accent = Color(hex: "00F5D4")
    static let accentLight = Color(hex: "00F5D4").opacity(0.1)
    static let accentMedium = Color(hex: "00F5D4").opacity(0.25)

    static let success = Color(hex: "00F5D4")
    static let warning = Color(hex: "FFD93D")
    static let error = Color(hex: "FF3F5E")
    static let info = Color(hex: "00BBF9")

    static let textPrimary = Color(hex: "E0E0F0")
    static let textSecondary = Color(hex: "7878A0")
    static let textTertiary = Color(hex: "454568")

    static let divider = Color(hex: "1A1A30")
    static let cardBackground = Color(hex: "0E0E1A")
}

enum AppTypography {
    static let heroTitle = Font.system(size: 32, weight: .bold, design: .monospaced)
    static let pageTitle = Font.system(size: 26, weight: .bold, design: .monospaced)
    static let sectionTitle = Font.system(size: 18, weight: .semibold, design: .monospaced)
    static let cardTitle = Font.system(size: 15, weight: .semibold, design: .monospaced)
    static let body = Font.system(size: 13, design: .monospaced)
    static let bodyBold = Font.system(size: 13, weight: .semibold, design: .monospaced)
    static let callout = Font.system(size: 12, design: .monospaced)
    static let caption = Font.system(size: 11, design: .monospaced)
    static let captionBold = Font.system(size: 11, weight: .semibold, design: .monospaced)
    static let caption2 = Font.system(size: 10, design: .monospaced)
    static let badge = Font.system(size: 9, weight: .bold, design: .monospaced)
    static let metric = Font.system(size: 36, weight: .bold, design: .monospaced)
    static let metricSmall = Font.system(size: 24, weight: .bold, design: .monospaced)
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
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 18
    static let full: CGFloat = 999
}

struct AppShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

enum AppShadow {
    static let sm = AppShadowStyle(color: Color(hex: "00F5D4").opacity(0.08), radius: 4, x: 0, y: 0)
    static let md = AppShadowStyle(color: Color(hex: "00F5D4").opacity(0.12), radius: 8, x: 0, y: 0)
    static let lg = AppShadowStyle(color: Color(hex: "00F5D4").opacity(0.18), radius: 16, x: 0, y: 0)
}

extension View {
    func appShadow(_ style: AppShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}

enum AppAnimation {
    static let springBounce = Animation.spring(response: 0.4, dampingFraction: 0.75)
    static let springSnappy = Animation.spring(response: 0.2, dampingFraction: 0.9)
    static let easeSmooth = Animation.easeInOut(duration: 0.2)
    static let easeSlow = Animation.easeInOut(duration: 0.45)
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
            colors: [Color(hex: "00F5D4").opacity(opacity), Color(hex: "00BBF9").opacity(opacity * 0.7)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    static func glass() -> some ShapeStyle { .ultraThinMaterial }
    static func scanline() -> LinearGradient {
        LinearGradient(
            colors: [Color(hex: "00F5D4").opacity(0.03), .clear, Color(hex: "00F5D4").opacity(0.03), .clear],
            startPoint: .top, endPoint: .bottom
        )
    }
}
