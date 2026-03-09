import SwiftUI

// MARK: - TreasuryPilot Theme: "Vault Terminal"
// Deep black backgrounds, emerald green accent, monospaced crypto terminal aesthetic

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
    static let background = Color(hex: "0A0A0F")
    static let secondaryBackground = Color(hex: "0F0F16")
    static let groupedBackground = Color(hex: "0A0A0F")
    static let tertiaryBackground = Color(hex: "14141E")
    static let elevatedBackground = Color(hex: "1A1A28")

    // Brand — Emerald vault green
    static let accent = Color(hex: "00D68F")
    static let accentLight = Color(hex: "00D68F").opacity(0.12)
    static let accentMedium = Color(hex: "00D68F").opacity(0.3)

    // Feedback
    static let success = Color(hex: "00D68F")
    static let warning = Color(hex: "FFB020")
    static let error = Color(hex: "FF4D4F")
    static let info = Color(hex: "40A9FF")

    // Text
    static let textPrimary = Color(hex: "E8E8ED")
    static let textSecondary = Color(hex: "8B8B9E")
    static let textTertiary = Color(hex: "52526B")

    // Surfaces
    static let divider = Color(hex: "1E1E2E")
    static let cardBackground = Color(hex: "12121C")
}

// MARK: - Typography (Monospaced terminal)

enum AppTypography {
    static let heroTitle = Font.system(size: 34, weight: .bold, design: .monospaced)
    static let pageTitle = Font.system(size: 28, weight: .bold, design: .monospaced)
    static let sectionTitle = Font.system(size: 20, weight: .semibold, design: .monospaced)
    static let cardTitle = Font.system(size: 16, weight: .semibold, design: .monospaced)
    static let body = Font.system(size: 14, design: .monospaced)
    static let bodyBold = Font.system(size: 14, weight: .semibold, design: .monospaced)
    static let callout = Font.system(size: 13, design: .monospaced)
    static let caption = Font.system(size: 12, design: .monospaced)
    static let captionBold = Font.system(size: 12, weight: .semibold, design: .monospaced)
    static let caption2 = Font.system(size: 11, design: .monospaced)
    static let badge = Font.system(size: 10, weight: .bold, design: .monospaced)
    static let metric = Font.system(size: 36, weight: .bold, design: .monospaced)
    static let metricSmall = Font.system(size: 24, weight: .bold, design: .monospaced)
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
    static let xl: CGFloat = 20
    static let full: CGFloat = 999
}

// MARK: - Shadows (Green glow)

struct AppShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

enum AppShadow {
    static let sm = AppShadowStyle(color: Color(hex: "00D68F").opacity(0.08), radius: 4, x: 0, y: 2)
    static let md = AppShadowStyle(color: Color(hex: "00D68F").opacity(0.12), radius: 8, x: 0, y: 4)
    static let lg = AppShadowStyle(color: Color(hex: "00D68F").opacity(0.18), radius: 16, x: 0, y: 8)
}

extension View {
    func appShadow(_ style: AppShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}

// MARK: - Animations

enum AppAnimation {
    static let springBounce = Animation.spring(response: 0.4, dampingFraction: 0.75)
    static let springSnappy = Animation.spring(response: 0.3, dampingFraction: 0.85)
    static let easeSmooth = Animation.easeInOut(duration: 0.25)
    static let easeSlow = Animation.easeInOut(duration: 0.5)
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
            colors: [Color(hex: "00D68F").opacity(opacity), Color(hex: "00B377").opacity(opacity * 0.7)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    static func glass() -> some ShapeStyle { .ultraThinMaterial }
    static func vaultGlow() -> LinearGradient {
        LinearGradient(
            colors: [Color(hex: "00D68F").opacity(0.15), Color(hex: "00D68F").opacity(0.0)],
            startPoint: .top, endPoint: .bottom
        )
    }
}
