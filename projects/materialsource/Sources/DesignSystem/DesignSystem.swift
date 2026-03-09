import SwiftUI

// MARK: - MaterialSource Theme: "Industrial Luxe"
// Warm charcoal backgrounds, copper/amber accent, B2B materials platform

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
    static let background = Color(hex: "1A1A1A")
    static let secondaryBackground = Color(hex: "212121")
    static let groupedBackground = Color(hex: "1A1A1A")
    static let tertiaryBackground = Color(hex: "2A2A2A")
    static let elevatedBackground = Color(hex: "333333")

    // Brand — Copper/Amber
    static let accent = Color(hex: "D4845C")
    static let accentLight = Color(hex: "D4845C").opacity(0.12)
    static let accentMedium = Color(hex: "D4845C").opacity(0.3)

    // Feedback
    static let success = Color(hex: "6BCB77")
    static let warning = Color(hex: "E8A838")
    static let error = Color(hex: "E85D4A")
    static let info = Color(hex: "5B9BD5")

    // Text
    static let textPrimary = Color(hex: "F0EDE8")
    static let textSecondary = Color(hex: "A09888")
    static let textTertiary = Color(hex: "706860")

    // Surfaces
    static let divider = Color(hex: "3A3530")
    static let cardBackground = Color(hex: "242220")
}

// MARK: - Typography (Clean sans-serif, serif titles)

enum AppTypography {
    static let heroTitle = Font.system(.largeTitle, design: .serif).weight(.bold)
    static let pageTitle = Font.system(.title, design: .serif).weight(.bold)
    static let sectionTitle = Font.system(.title3, design: .default).weight(.semibold)
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

// MARK: - Spacing (8pt grid)

enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

enum AppRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 10
    static let lg: CGFloat = 14
    static let xl: CGFloat = 22
    static let full: CGFloat = 999
}

// MARK: - Shadows (Warm shadows)

struct AppShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

enum AppShadow {
    static let sm = AppShadowStyle(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
    static let md = AppShadowStyle(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
    static let lg = AppShadowStyle(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 8)
}

extension View {
    func appShadow(_ style: AppShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}

// MARK: - Animations

enum AppAnimation {
    static let springBounce = Animation.spring(response: 0.45, dampingFraction: 0.7)
    static let springSnappy = Animation.spring(response: 0.3, dampingFraction: 0.85)
    static let easeSmooth = Animation.easeInOut(duration: 0.3)
    static let easeSlow = Animation.easeInOut(duration: 0.55)
}

// MARK: - Haptics

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

// MARK: - Gradient Helpers

enum AppGradient {
    static func accent(opacity: CGFloat = 1.0) -> LinearGradient {
        LinearGradient(
            colors: [Color(hex: "D4845C").opacity(opacity), Color(hex: "B86B3F").opacity(opacity * 0.8)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    static func glass() -> some ShapeStyle { .ultraThinMaterial }
    static func warmSheen() -> LinearGradient {
        LinearGradient(
            colors: [Color(hex: "D4845C").opacity(0.08), Color(hex: "E8A838").opacity(0.04), .clear],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}
