import SwiftUI

enum NETheme {
    // MARK: - Core Colors
    static let background = Color(hex: "#050A14")
    static let surface = Color(hex: "#0A1628")
    static let surfaceElevated = Color(hex: "#0F1D33")
    static let surfaceOverlay = Color(hex: "#162540")
    static let accent = Color(hex: "#00E5CC") // Teal
    static let accentSecondary = Color(hex: "#4FC3F7") // Light blue
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#8899AA")
    static let textTertiary = Color(hex: "#556677")
    static let border = Color(hex: "#1A2A40")

    // MARK: - Severity Colors
    static let severityLow = Color(hex: "#4CAF50")
    static let severityMedium = Color(hex: "#FFC107")
    static let severityHigh = Color(hex: "#FF9800")
    static let severityCritical = Color(hex: "#F44336")
    static let severitySevere = Color(hex: "#D32F2F")

    // MARK: - Category Colors
    static let earthquakeColor = Color(hex: "#FF8A65")
    static let fireColor = Color(hex: "#FF5252")
    static let weatherColor = Color(hex: "#42A5F5")
    static let satelliteColor = Color(hex: "#CE93D8")
    static let flightColor = Color(hex: "#90CAF9")
    static let newsColor = Color(hex: "#A5D6A7")
    static let marineColor = Color(hex: "#4DD0E1")
    static let cyberColor = Color(hex: "#FFAB40")

    // MARK: - Typography
    static func heading(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }

    static func subheading(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    static func body(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func mono(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }

    static func caption(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    // MARK: - Glass Card
    static let glassGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.08),
            Color.white.opacity(0.02)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassStroke = LinearGradient(
        colors: [
            Color.white.opacity(0.15),
            Color.white.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - View Modifiers
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(NETheme.glassGradient)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(NETheme.glassStroke, lineWidth: 0.5)
            )
    }
}

struct SeverityBadge: View {
    let level: ThreatLevel

    var body: some View {
        Text(level.label)
            .font(NETheme.mono(10))
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color(hex: level.colorHex))
            .clipShape(Capsule())
    }
}

struct DataFreshnessPill: View {
    let lastUpdate: Date?

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(freshnessColor)
                .frame(width: 6, height: 6)
            Text(freshnessText)
                .font(NETheme.caption(10))
                .foregroundStyle(NETheme.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(NETheme.surface.opacity(0.8))
        .clipShape(Capsule())
    }

    private var freshnessColor: Color {
        guard let date = lastUpdate else { return .gray }
        let age = Date().timeIntervalSince(date)
        if age < 300 { return NETheme.severityLow }
        if age < 900 { return NETheme.severityMedium }
        return NETheme.severityHigh
    }

    private var freshnessText: String {
        guard let date = lastUpdate else { return "No data" }
        let age = Date().timeIntervalSince(date)
        if age < 60 { return "Live" }
        if age < 3600 { return "\(Int(age / 60))m ago" }
        return "\(Int(age / 3600))h ago"
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}
