import SwiftUI

// MARK: - Colors

enum AppColors {
    // Backgrounds (auto-adapt light/dark)
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let groupedBackground = Color(.systemGroupedBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    static let elevatedBackground = Color(.tertiarySystemBackground)

    // Brand
    static let accent = Color.accentColor
    static let accentLight = Color.accentColor.opacity(0.12)
    static let accentMedium = Color.accentColor.opacity(0.3)

    // Feedback
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue

    // Text
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)

    // Surfaces
    static let divider = Color(.separator)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
}

// MARK: - Typography

enum AppTypography {
    static let heroTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let pageTitle = Font.system(.title, design: .default).weight(.bold)
    static let sectionTitle = Font.system(.title3, design: .default).weight(.semibold)
    static let cardTitle = Font.system(.headline, design: .default).weight(.semibold)
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
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 999
}

// MARK: - Shadows

struct AppShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

enum AppShadow {
    static let sm = AppShadowStyle(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    static let md = AppShadowStyle(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    static let lg = AppShadowStyle(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
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

enum AppHaptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// MARK: - Gradient Helpers

enum AppGradient {
    static func accent(opacity: CGFloat = 1.0) -> LinearGradient {
        LinearGradient(
            colors: [AppColors.accent.opacity(opacity), AppColors.accent.opacity(opacity * 0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func glass() -> some ShapeStyle {
        .ultraThinMaterial
    }
}
