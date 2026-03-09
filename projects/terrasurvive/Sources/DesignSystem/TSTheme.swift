import SwiftUI

// MARK: - TerraSurvive Design System
// Rugged, functional outdoor/survival aesthetic

enum TSTheme {
    // MARK: Core Colors
    static let background = Color(hex: "0D1108")
    static let surface = Color(hex: "1A2614")
    static let surfaceElevated = Color(hex: "243320")
    static let surfaceHighlight = Color(hex: "2E4228")

    // MARK: Accent Colors
    static let accentOrange = Color(hex: "FF8C00")
    static let accentGreen = Color(hex: "4CAF50")
    static let dangerRed = Color(hex: "F44336")
    static let waterBlue = Color(hex: "2196F3")
    static let warningYellow = Color(hex: "FFC107")
    static let sandBrown = Color(hex: "D2B48C")

    // MARK: Text Colors
    static let textPrimary = Color(hex: "F5F5F0")
    static let textSecondary = Color(hex: "A8B89E")
    static let textTertiary = Color(hex: "6B7A63")

    // MARK: Semantic Colors
    static let safe = accentGreen
    static let caution = warningYellow
    static let danger = dangerRed
    static let water = waterBlue
    static let fire = accentOrange

    // MARK: Gradients
    static let backgroundGradient = LinearGradient(
        colors: [background, surface],
        startPoint: .top,
        endPoint: .bottom
    )

    static let dangerGradient = LinearGradient(
        colors: [dangerRed.opacity(0.8), dangerRed.opacity(0.3)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let safeGradient = LinearGradient(
        colors: [accentGreen.opacity(0.8), accentGreen.opacity(0.3)],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: Typography
    enum Font {
        static func heading(_ size: CGFloat = 24) -> SwiftUI.Font {
            .system(size: size, weight: .bold, design: .default)
        }
        static func subheading(_ size: CGFloat = 18) -> SwiftUI.Font {
            .system(size: size, weight: .semibold, design: .default)
        }
        static func body(_ size: CGFloat = 16) -> SwiftUI.Font {
            .system(size: size, weight: .regular, design: .default)
        }
        static func caption(_ size: CGFloat = 13) -> SwiftUI.Font {
            .system(size: size, weight: .medium, design: .default)
        }
        static func mono(_ size: CGFloat = 14) -> SwiftUI.Font {
            .system(size: size, weight: .medium, design: .monospaced)
        }
    }

    // MARK: Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: Corner Radius
    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers

struct TSCardModifier: ViewModifier {
    var padding: CGFloat = TSTheme.Spacing.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(TSTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: TSTheme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: TSTheme.Radius.md)
                    .strokeBorder(TSTheme.surfaceHighlight, lineWidth: 1)
            )
    }
}

struct TSDangerBadgeModifier: ViewModifier {
    let level: DangerLevel

    func body(content: Content) -> some View {
        content
            .font(TSTheme.Font.caption(11))
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(level.color)
            .clipShape(Capsule())
    }
}

struct TSDifficultyBadgeModifier: ViewModifier {
    let difficulty: GuideDifficulty

    func body(content: Content) -> some View {
        content
            .font(TSTheme.Font.caption(11))
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(difficulty.color)
            .clipShape(Capsule())
    }
}

extension View {
    func tsCard(padding: CGFloat = TSTheme.Spacing.lg) -> some View {
        modifier(TSCardModifier(padding: padding))
    }

    func tsDangerBadge(level: DangerLevel) -> some View {
        modifier(TSDangerBadgeModifier(level: level))
    }

    func tsDifficultyBadge(difficulty: GuideDifficulty) -> some View {
        modifier(TSDifficultyBadgeModifier(difficulty: difficulty))
    }
}

// MARK: - Reusable Components

struct TSSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."

    var body: some View {
        HStack(spacing: TSTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(TSTheme.textTertiary)
            TextField(placeholder, text: $text)
                .foregroundStyle(TSTheme.textPrimary)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(TSTheme.textTertiary)
                }
            }
        }
        .padding(TSTheme.Spacing.md)
        .background(TSTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: TSTheme.Radius.md))
    }
}

struct TSSectionHeader: View {
    let icon: String
    let title: String
    var count: Int? = nil

    var body: some View {
        HStack(spacing: TSTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(TSTheme.accentOrange)
                .font(.system(size: 16, weight: .semibold))
            Text(title)
                .font(TSTheme.Font.subheading())
                .foregroundStyle(TSTheme.textPrimary)
            if let count {
                Text("(\(count))")
                    .font(TSTheme.Font.caption())
                    .foregroundStyle(TSTheme.textTertiary)
            }
            Spacer()
        }
        .padding(.horizontal, TSTheme.Spacing.lg)
        .padding(.vertical, TSTheme.Spacing.sm)
    }
}
