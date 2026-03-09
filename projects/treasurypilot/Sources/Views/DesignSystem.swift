import SwiftUI

// MARK: - TreasuryPilot Design System
// Dark navy + gold color scheme for a tier-1 finance aesthetic.

enum TPTheme {

    // MARK: Colors

    /// Primary background — deep navy
    static let background = Color(hex: 0x0B1120)
    /// Elevated surface — slightly lighter navy for cards
    static let surface = Color(hex: 0x111B2E)
    /// Raised surface — for modals, popovers, input fields
    static let surfaceRaised = Color(hex: 0x162240)
    /// Accent gold — primary CTA, highlights, key metrics
    static let gold = Color(hex: 0xD4AF37)
    /// Accent secondary — links, info badges, secondary highlights
    static let accentSecondary = Color(hex: 0x4FC3F7)
    /// Success green
    static let success = Color(hex: 0x4CAF50)
    /// Warning amber
    static let warning = Color(hex: 0xFFA726)
    /// Danger red
    static let danger = Color(hex: 0xEF5350)

    /// Primary text — bright white with slight warmth
    static let textPrimary = Color(hex: 0xF0F0F5)
    /// Secondary text — muted label gray
    static let textSecondary = Color(hex: 0x8A92A6)
    /// Tertiary text — very subtle hints
    static let textTertiary = Color(hex: 0x565E72)

    /// Divider / border stroke
    static let border = Color.white.opacity(0.08)

    // MARK: Gradients

    /// Gold shimmer gradient for hero stat values
    static let goldGradient = LinearGradient(
        colors: [Color(hex: 0xD4AF37), Color(hex: 0xF5D76E)],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Surface glow gradient for cards
    static let surfaceGradient = LinearGradient(
        colors: [surface, surface.opacity(0.85)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Accent background gradient
    static let accentGradient = LinearGradient(
        colors: [Color(hex: 0xD4AF37).opacity(0.15), Color(hex: 0xD4AF37).opacity(0.03)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Typography Helpers

    static func heading(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func subheading(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func mono(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }

    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    // MARK: Corner Radius

    static let cornerRadius: CGFloat = 14
    static let cornerRadiusSmall: CGFloat = 8

    // MARK: Spacing

    static let paddingStandard: CGFloat = 16
    static let paddingCompact: CGFloat = 12
    static let sectionSpacing: CGFloat = 20
}

// MARK: - Color Extension (Hex Init)

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

// MARK: - Glass Card Modifier

/// A frosted glass card style used throughout TreasuryPilot.
/// Adds a translucent background with a subtle border glow.
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = TPTheme.cornerRadius
    var padding: CGFloat = TPTheme.paddingStandard
    var showBorder: Bool = true

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(TPTheme.surface.opacity(0.92))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        showBorder
                            ? TPTheme.border
                            : Color.clear,
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

/// Gold-accented glass card for hero / premium sections.
struct GoldGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = TPTheme.cornerRadius

    func body(content: Content) -> some View {
        content
            .padding(TPTheme.paddingStandard)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(TPTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(TPTheme.accentGradient)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(TPTheme.gold.opacity(0.25), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    /// Apply the standard glass card style.
    func glassCard(
        cornerRadius: CGFloat = TPTheme.cornerRadius,
        padding: CGFloat = TPTheme.paddingStandard,
        showBorder: Bool = true
    ) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, padding: padding, showBorder: showBorder))
    }

    /// Apply the gold-accented glass card style (hero metrics).
    func goldGlassCard(cornerRadius: CGFloat = TPTheme.cornerRadius) -> some View {
        modifier(GoldGlassCardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Themed Section Header

struct TPSectionHeader: View {
    let title: String
    var icon: String? = nil
    var trailing: String? = nil

    var body: some View {
        HStack {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(TPTheme.gold)
            }
            Text(title)
                .font(TPTheme.subheading(14))
                .foregroundStyle(TPTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(1.2)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(TPTheme.caption())
                    .foregroundStyle(TPTheme.textTertiary)
            }
        }
    }
}

// MARK: - Themed Divider

struct TPDivider: View {
    var body: some View {
        Rectangle()
            .fill(TPTheme.border)
            .frame(height: 1)
    }
}
