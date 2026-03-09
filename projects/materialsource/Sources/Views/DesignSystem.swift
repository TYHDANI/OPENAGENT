import SwiftUI

// MARK: - MSTheme: Industrial/Engineering Design System

enum MSTheme {
    // MARK: - Colors

    /// Dark industrial background (#0D1117)
    static let background = Color(red: 13/255, green: 17/255, blue: 23/255)

    /// Elevated surface (#161B22)
    static let surface = Color(red: 22/255, green: 27/255, blue: 34/255)

    /// Card/panel surface — slightly brighter than surface (#1C2128)
    static let surfaceElevated = Color(red: 28/255, green: 33/255, blue: 40/255)

    /// Tech blue accent (#58A6FF)
    static let accent = Color(red: 88/255, green: 166/255, blue: 255/255)

    /// Success green (#3FB950)
    static let success = Color(red: 63/255, green: 185/255, blue: 80/255)

    /// Warning amber (#D29922)
    static let warning = Color(red: 210/255, green: 153/255, blue: 34/255)

    /// Error red (#F85149)
    static let error = Color(red: 248/255, green: 81/255, blue: 73/255)

    /// Primary text — bright white (#E6EDF3)
    static let textPrimary = Color(red: 230/255, green: 237/255, blue: 243/255)

    /// Secondary text — muted (#8B949E)
    static let textSecondary = Color(red: 139/255, green: 148/255, blue: 158/255)

    /// Tertiary text — very dim (#484F58)
    static let textTertiary = Color(red: 72/255, green: 79/255, blue: 88/255)

    /// Border color (#30363D)
    static let border = Color(red: 48/255, green: 54/255, blue: 61/255)

    /// Subtle highlight for hover/active states
    static let highlight = Color.white.opacity(0.04)

    // MARK: - Category Colors

    static func categoryColor(_ category: String) -> Color {
        switch category {
        case "Aerospace Alloys", "Titanium Alloys":
            return Color(red: 88/255, green: 166/255, blue: 255/255) // tech blue
        case "Nickel Alloys":
            return Color(red: 188/255, green: 140/255, blue: 255/255) // purple
        case "Stainless Steels":
            return Color(red: 121/255, green: 192/255, blue: 255/255) // light blue
        case "Aluminum Alloys":
            return Color(red: 63/255, green: 185/255, blue: 80/255)  // green
        case "Composites":
            return Color(red: 210/255, green: 153/255, blue: 34/255) // amber
        case "Ceramics":
            return Color(red: 255/255, green: 123/255, blue: 114/255) // coral
        case "Semiconductors":
            return Color(red: 219/255, green: 124/255, blue: 240/255) // magenta
        default:
            return Color(red: 139/255, green: 148/255, blue: 158/255) // neutral
        }
    }

    static func categoryIcon(_ category: String) -> String {
        switch category {
        case "Aerospace Alloys", "Titanium Alloys":
            return "airplane"
        case "Nickel Alloys":
            return "flame.fill"
        case "Stainless Steels":
            return "shield.lefthalf.filled"
        case "Aluminum Alloys":
            return "cube.fill"
        case "Composites":
            return "square.stack.3d.up.fill"
        case "Ceramics":
            return "hexagon.fill"
        case "Semiconductors":
            return "cpu"
        default:
            return "cube.transparent"
        }
    }

    // MARK: - Category Gradient

    static func categoryGradient(_ category: String) -> LinearGradient {
        let base = categoryColor(category)
        return LinearGradient(
            colors: [base, base.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Typography Helpers

    static func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.title3)
            .fontWeight(.bold)
            .foregroundStyle(textPrimary)
    }

    static func caption(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(textSecondary)
    }

    static func statValue(_ text: String) -> some View {
        Text(text)
            .font(.system(.title2, design: .monospaced))
            .fontWeight(.bold)
            .foregroundStyle(textPrimary)
    }

    // MARK: - Spacing

    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let itemSpacing: CGFloat = 12
    static let cornerRadius: CGFloat = 14
    static let smallCornerRadius: CGFloat = 10
}

// MARK: - Glass Card Modifier

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = MSTheme.cornerRadius
    var padding: CGFloat = MSTheme.cardPadding

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(MSTheme.border.opacity(0.5), lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - Industrial Card Modifier (opaque dark card)

struct IndustrialCardModifier: ViewModifier {
    var cornerRadius: CGFloat = MSTheme.cornerRadius

    func body(content: Content) -> some View {
        content
            .padding(MSTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(MSTheme.surfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(MSTheme.border, lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - Glow Accent Modifier

struct GlowAccentModifier: ViewModifier {
    var color: Color = MSTheme.accent
    var radius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.3), radius: radius, x: 0, y: 4)
    }
}

// MARK: - Animated Shimmer (for loading states)

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.08),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// MARK: - Badge View

struct MSBadge: View {
    let text: String
    var color: Color = MSTheme.accent
    var style: BadgeStyle = .filled

    enum BadgeStyle {
        case filled
        case outlined
        case subtle
    }

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeBackground)
            .foregroundStyle(badgeForeground)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private var badgeBackground: some View {
        switch style {
        case .filled:
            Capsule().fill(color)
        case .outlined:
            Capsule().fill(Color.clear)
                .overlay(Capsule().stroke(color, lineWidth: 1))
        case .subtle:
            Capsule().fill(color.opacity(0.15))
        }
    }

    private var badgeForeground: Color {
        switch style {
        case .filled: return .white
        case .outlined: return color
        case .subtle: return color
        }
    }
}

// MARK: - Star Rating View

struct StarRatingView: View {
    let rating: Double
    var maxRating: Int = 5
    var size: CGFloat = 12
    var color: Color = MSTheme.warning

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<maxRating, id: \.self) { index in
                starImage(for: index)
                    .font(.system(size: size))
                    .foregroundStyle(index < Int(rating.rounded()) ? color : MSTheme.textTertiary)
            }
            Text(String(format: "%.1f", rating))
                .font(.system(size: size, weight: .semibold, design: .monospaced))
                .foregroundStyle(MSTheme.textSecondary)
        }
    }

    private func starImage(for index: Int) -> Image {
        let threshold = Double(index)
        if rating >= threshold + 1.0 {
            return Image(systemName: "star.fill")
        } else if rating >= threshold + 0.5 {
            return Image(systemName: "star.leadinghalf.filled")
        } else {
            return Image(systemName: "star")
        }
    }
}

// MARK: - Quick Stat Card

struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = MSTheme.accent

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.system(.headline, design: .monospaced))
                .fontWeight(.bold)
                .foregroundStyle(MSTheme.textPrimary)

            Text(label)
                .font(.caption2)
                .foregroundStyle(MSTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: MSTheme.smallCornerRadius)
                .fill(MSTheme.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: MSTheme.smallCornerRadius)
                        .stroke(color.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Section Header with Icon

struct MSSectionHeader: View {
    let title: String
    let icon: String
    var color: Color = MSTheme.accent
    var trailingContent: AnyView? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)

            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(MSTheme.textPrimary)

            Spacer()

            if let trailing = trailingContent {
                trailing
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply glass card styling (translucent background)
    func glassCard(cornerRadius: CGFloat = MSTheme.cornerRadius, padding: CGFloat = MSTheme.cardPadding) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, padding: padding))
    }

    /// Apply industrial card styling (dark opaque background)
    func industrialCard(cornerRadius: CGFloat = MSTheme.cornerRadius) -> some View {
        modifier(IndustrialCardModifier(cornerRadius: cornerRadius))
    }

    /// Apply accent glow shadow
    func glowAccent(color: Color = MSTheme.accent, radius: CGFloat = 12) -> some View {
        modifier(GlowAccentModifier(color: color, radius: radius))
    }

    /// Apply shimmer loading effect
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }

    /// Industrial/dark section background
    func msBackground() -> some View {
        self.background(MSTheme.background)
    }
}
