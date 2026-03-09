import SwiftUI

// MARK: - Habit Streak Theme: "Momentum"
// Dark navy backgrounds, coral/orange accent, bold and motivational

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
    static let background = Color(hex: "0F172A")
    static let secondaryBackground = Color(hex: "1E293B")
    static let groupedBackground = Color(hex: "0F172A")
    static let tertiaryBackground = Color(hex: "283548")
    static let elevatedBackground = Color(hex: "334155")

    static let accent = Color(hex: "F97316")
    static let accentLight = Color(hex: "F97316").opacity(0.12)
    static let accentMedium = Color(hex: "F97316").opacity(0.3)

    static let success = Color(hex: "22C55E")
    static let warning = Color(hex: "FBBF24")
    static let error = Color(hex: "EF4444")
    static let info = Color(hex: "38BDF8")

    static let textPrimary = Color(hex: "F8FAFC")
    static let textSecondary = Color(hex: "94A3B8")
    static let textTertiary = Color(hex: "64748B")

    static let divider = Color(hex: "334155")
    static let cardBackground = Color(hex: "1E293B")

    // Streak fire colors
    static let streakFire = Color(hex: "F97316")
    static let streakGold = Color(hex: "FBBF24")
    static let streakPlatinum = Color(hex: "E2E8F0")
}

enum AppTypography {
    static let heroTitle = Font.system(.largeTitle, design: .rounded).weight(.black)
    static let pageTitle = Font.system(.title, design: .rounded).weight(.bold)
    static let sectionTitle = Font.system(.title3, design: .rounded).weight(.bold)
    static let cardTitle = Font.system(.headline, design: .rounded).weight(.bold)
    static let body = Font.system(.body, design: .rounded)
    static let bodyBold = Font.system(.body, design: .rounded).weight(.semibold)
    static let callout = Font.system(.callout, design: .rounded)
    static let caption = Font.system(.caption, design: .rounded)
    static let captionBold = Font.system(.caption, design: .rounded).weight(.semibold)
    static let caption2 = Font.system(.caption2, design: .rounded)
    static let badge = Font.system(.caption2, design: .rounded).weight(.black)
    static let metric = Font.system(size: 42, weight: .black, design: .rounded)
    static let metricSmall = Font.system(size: 28, weight: .bold, design: .rounded)
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
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
    static let full: CGFloat = 999
}

struct AppShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

enum AppShadow {
    static let sm = AppShadowStyle(color: Color(hex: "F97316").opacity(0.1), radius: 4, x: 0, y: 2)
    static let md = AppShadowStyle(color: Color(hex: "F97316").opacity(0.15), radius: 8, x: 0, y: 4)
    static let lg = AppShadowStyle(color: Color(hex: "F97316").opacity(0.2), radius: 16, x: 0, y: 8)
}

extension View {
    func appShadow(_ style: AppShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}

enum AppAnimation {
    static let springBounce = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let springSnappy = Animation.spring(response: 0.25, dampingFraction: 0.8)
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
            colors: [Color(hex: "F97316").opacity(opacity), Color(hex: "FBBF24").opacity(opacity * 0.8)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    static func glass() -> some ShapeStyle { .ultraThinMaterial }
    static func fire() -> LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FBBF24"), Color(hex: "F97316"), Color(hex: "EF4444")],
            startPoint: .bottom, endPoint: .top
        )
    }
}
