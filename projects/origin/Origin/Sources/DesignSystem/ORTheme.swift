import SwiftUI

// MARK: - Origin Design System
// Premium dating app aesthetic inspired by Raya — dark, elegant, warm tones

enum ORTheme {

    // MARK: - Color Palette

    enum Colors {
        // Core backgrounds
        static let background = Color(hex: 0x0A0A14)
        static let surface = Color(hex: 0x14142A)
        static let surfaceElevated = Color(hex: 0x1E1E3A)
        static let surfaceCard = Color(hex: 0x1A1A32)

        // Accent colors
        static let accentRose = Color(hex: 0xE91E63)
        static let accentGold = Color(hex: 0xFFD700)
        static let accentWarm = Color(hex: 0xFF6B6B)
        static let accentSoft = Color(hex: 0xF8BBD0)

        // Text hierarchy
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let textTertiary = Color.white.opacity(0.45)
        static let textMuted = Color.white.opacity(0.3)

        // Semantic
        static let success = Color(hex: 0x4CAF50)
        static let warning = Color(hex: 0xFFC107)
        static let error = Color(hex: 0xF44336)
        static let info = Color(hex: 0x64B5F6)

        // Compatibility score gradient stops
        static let compatLow = Color(hex: 0xFF6B6B)
        static let compatMedium = Color(hex: 0xFFD700)
        static let compatHigh = Color(hex: 0x4CAF50)

        // Overlays
        static let cardOverlay = Color.black.opacity(0.4)
        static let sheetBackground = Color(hex: 0x0D0D1A).opacity(0.95)

        // Borders
        static let border = Color.white.opacity(0.08)
        static let borderActive = Color(hex: 0xE91E63).opacity(0.5)
    }

    // MARK: - Typography

    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
        static let captionBold = Font.system(size: 12, weight: .semibold, design: .default)

        // Special display fonts for hero text
        static let display = Font.system(size: 42, weight: .bold, design: .serif)
        static let displaySmall = Font.system(size: 36, weight: .bold, design: .serif)

        // Monospaced for scores/numbers
        static let score = Font.system(size: 48, weight: .bold, design: .rounded)
        static let scoreSmall = Font.system(size: 24, weight: .bold, design: .rounded)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let pill: CGFloat = 100
    }

    // MARK: - Shadows

    enum Shadow {
        static let card = SwiftUI.Color.black.opacity(0.3)
        static let elevated = SwiftUI.Color.black.opacity(0.5)
        static let glow = Color(hex: 0xE91E63).opacity(0.3)
    }

    // MARK: - Gradients

    enum Gradients {
        static let roseGold = LinearGradient(
            colors: [Color(hex: 0xE91E63), Color(hex: 0xFFD700)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let warmSunset = LinearGradient(
            colors: [Color(hex: 0xE91E63), Color(hex: 0xFF6B6B), Color(hex: 0xFFD700)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let darkFade = LinearGradient(
            colors: [Color.clear, Color(hex: 0x0A0A14)],
            startPoint: .top,
            endPoint: .bottom
        )

        static let cardOverlay = LinearGradient(
            colors: [Color.clear, Color.clear, Color.black.opacity(0.7)],
            startPoint: .top,
            endPoint: .bottom
        )

        static let surfaceGradient = LinearGradient(
            colors: [Color(hex: 0x14142A), Color(hex: 0x0A0A14)],
            startPoint: .top,
            endPoint: .bottom
        )

        static func compatibilityGradient(score: Double) -> LinearGradient {
            if score >= 0.8 {
                return LinearGradient(
                    colors: [Color(hex: 0x4CAF50), Color(hex: 0x81C784)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else if score >= 0.6 {
                return LinearGradient(
                    colors: [Color(hex: 0xFFD700), Color(hex: 0xFFC107)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(hex: 0xFF6B6B), Color(hex: 0xE91E63)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
    }

    // MARK: - Animation

    enum Animation {
        static let springy = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.7)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        static let cardSwipe = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}

// MARK: - View Modifiers

struct ORCardStyle: ViewModifier {
    var elevated: Bool = false

    func body(content: Content) -> some View {
        content
            .background(elevated ? ORTheme.Colors.surfaceElevated : ORTheme.Colors.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: ORTheme.Radius.lg, style: .continuous))
            .shadow(color: elevated ? ORTheme.Shadow.elevated : ORTheme.Shadow.card, radius: elevated ? 12 : 6, y: 4)
    }
}

struct ORPrimaryButton: ViewModifier {
    var isEnabled: Bool = true

    func body(content: Content) -> some View {
        content
            .font(ORTheme.Typography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                isEnabled
                    ? AnyShapeStyle(ORTheme.Gradients.roseGold)
                    : AnyShapeStyle(ORTheme.Colors.surfaceElevated)
            )
            .clipShape(RoundedRectangle(cornerRadius: ORTheme.Radius.md, style: .continuous))
    }
}

struct ORSecondaryButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(ORTheme.Typography.headline)
            .foregroundStyle(ORTheme.Colors.accentRose)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(ORTheme.Colors.accentRose.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: ORTheme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ORTheme.Radius.md, style: .continuous)
                    .stroke(ORTheme.Colors.accentRose.opacity(0.3), lineWidth: 1)
            )
    }
}

struct ORTextField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(ORTheme.Typography.body)
            .foregroundStyle(ORTheme.Colors.textPrimary)
            .padding(.horizontal, ORTheme.Spacing.lg)
            .frame(height: 48)
            .background(ORTheme.Colors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: ORTheme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ORTheme.Radius.md, style: .continuous)
                    .stroke(ORTheme.Colors.border, lineWidth: 1)
            )
    }
}

// MARK: - View Extension Helpers

extension View {
    func orCard(elevated: Bool = false) -> some View {
        modifier(ORCardStyle(elevated: elevated))
    }

    func orPrimaryButton(isEnabled: Bool = true) -> some View {
        modifier(ORPrimaryButton(isEnabled: isEnabled))
    }

    func orSecondaryButton() -> some View {
        modifier(ORSecondaryButton())
    }

    func orTextField() -> some View {
        modifier(ORTextField())
    }
}

// MARK: - Compatibility Score Badge

struct CompatibilityBadge: View {
    let score: Double
    var size: BadgeSize = .regular

    enum BadgeSize {
        case small, regular, large

        var diameter: CGFloat {
            switch self {
            case .small: return 36
            case .regular: return 52
            case .large: return 72
            }
        }

        var font: Font {
            switch self {
            case .small: return ORTheme.Typography.captionBold
            case .regular: return ORTheme.Typography.headline
            case .large: return ORTheme.Typography.scoreSmall
            }
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(ORTheme.Gradients.compatibilityGradient(score: score))
                .frame(width: size.diameter, height: size.diameter)
                .shadow(color: compatColor.opacity(0.4), radius: 8, y: 2)

            Text("\(Int(score * 100))%")
                .font(size.font)
                .foregroundStyle(.white)
        }
    }

    private var compatColor: Color {
        if score >= 0.8 { return ORTheme.Colors.compatHigh }
        if score >= 0.6 { return ORTheme.Colors.compatMedium }
        return ORTheme.Colors.compatLow
    }
}

// MARK: - Verified Badge

struct VerifiedBadge: View {
    var body: some View {
        Image(systemName: "checkmark.seal.fill")
            .font(.system(size: 14))
            .foregroundStyle(ORTheme.Colors.accentGold)
            .shadow(color: ORTheme.Colors.accentGold.opacity(0.5), radius: 4)
    }
}

// MARK: - Tag Chip

struct ORChip: View {
    let text: String
    var icon: String? = nil
    var tint: Color = ORTheme.Colors.accentRose

    var body: some View {
        HStack(spacing: ORTheme.Spacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(ORTheme.Typography.caption)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, ORTheme.Spacing.sm)
        .padding(.vertical, ORTheme.Spacing.xs)
        .background(tint.opacity(0.12))
        .clipShape(Capsule())
    }
}
