import SwiftUI

// MARK: - VDColors

enum VDColors {
    static let background = Color(hex: "0A1018")
    static let surface = Color(hex: "111D2A")
    static let surfaceElevated = Color(hex: "162536")
    static let surfaceTertiary = Color(hex: "1C2F42")

    static let accentTeal = Color(hex: "00BFA5")
    static let accentPurple = Color(hex: "7C4DFF")
    static let heartRed = Color(hex: "FF5252")
    static let warningAmber = Color(hex: "FFB74D")
    static let successGreen = Color(hex: "66BB6A")
    static let sleepBlue = Color(hex: "42A5F5")
    static let oxygenCyan = Color(hex: "26C6DA")
    static let glucoseOrange = Color(hex: "FFA726")

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.38)
    static let textInverse = Color(hex: "0A1018")

    static let divider = Color.white.opacity(0.08)
    static let shimmer = Color.white.opacity(0.04)

    static let gradientTeal = LinearGradient(
        colors: [Color(hex: "00BFA5"), Color(hex: "00897B")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientPurple = LinearGradient(
        colors: [Color(hex: "7C4DFF"), Color(hex: "536DFE")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientHeart = LinearGradient(
        colors: [Color(hex: "FF5252"), Color(hex: "FF1744")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientSleep = LinearGradient(
        colors: [Color(hex: "42A5F5"), Color(hex: "7C4DFF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientScore = LinearGradient(
        colors: [Color(hex: "00BFA5"), Color(hex: "7C4DFF")],
        startPoint: .leading,
        endPoint: .trailing
    )
}


// MARK: - VDTypography

enum VDTypography {
    static let heroTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let sectionTitle = Font.system(size: 22, weight: .bold, design: .rounded)
    static let cardTitle = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let bodyBold = Font.system(size: 15, weight: .semibold)
    static let body = Font.system(size: 15, weight: .regular)
    static let caption = Font.system(size: 13, weight: .medium)
    static let captionSmall = Font.system(size: 11, weight: .medium)
    static let metricLarge = Font.system(size: 48, weight: .bold, design: .rounded)
    static let metricMedium = Font.system(size: 28, weight: .bold, design: .rounded)
    static let metricSmall = Font.system(size: 20, weight: .bold, design: .rounded)
    static let tabLabel = Font.system(size: 10, weight: .medium)
}


// MARK: - VDSpacing

enum VDSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}


// MARK: - VDRadius

enum VDRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let pill: CGFloat = 100
}


// MARK: - VDAnimation

enum VDAnimation {
    static let springBounce = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let springSmooth = Animation.spring(response: 0.4, dampingFraction: 0.9)
    static let easeOut = Animation.easeOut(duration: 0.25)
    static let slow = Animation.easeInOut(duration: 0.6)
}


// MARK: - VDCard Modifier

struct VDCardModifier: ViewModifier {
    var padding: CGFloat = VDSpacing.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(VDColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: VDRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: VDRadius.lg, style: .continuous)
                    .strokeBorder(VDColors.divider, lineWidth: 1)
            )
    }
}

extension View {
    func vdCard(padding: CGFloat = VDSpacing.lg) -> some View {
        modifier(VDCardModifier(padding: padding))
    }
}


// MARK: - GlowModifier

struct GlowModifier: ViewModifier {
    let color: Color
    var radius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.3), radius: radius, x: 0, y: 4)
            .shadow(color: color.opacity(0.1), radius: radius * 2, x: 0, y: 8)
    }
}

extension View {
    func vdGlow(_ color: Color, radius: CGFloat = 12) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}


// MARK: - ShimmerView

struct VDShimmerView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(VDColors.shimmer)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.06), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: phase)
            )
            .clipShape(RoundedRectangle(cornerRadius: VDRadius.md))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
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


// MARK: - Metric Badge

struct VDMetricBadge: View {
    let icon: String
    let label: String
    let value: String
    var color: Color = VDColors.accentTeal
    var trend: Double? = nil

    var body: some View {
        VStack(spacing: VDSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            Text(value)
                .font(VDTypography.metricSmall)
                .foregroundStyle(VDColors.textPrimary)
                .contentTransition(.numericText())

            Text(label)
                .font(VDTypography.captionSmall)
                .foregroundStyle(VDColors.textSecondary)

            if let trend {
                HStack(spacing: VDSpacing.xxs) {
                    Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 9, weight: .bold))
                    Text("\(abs(trend), specifier: "%.0f")%")
                        .font(VDTypography.captionSmall)
                }
                .foregroundStyle(trend >= 0 ? VDColors.successGreen : VDColors.heartRed)
            }
        }
        .frame(maxWidth: .infinity)
    }
}


// MARK: - Section Header

struct VDSectionHeader: View {
    let title: String
    var icon: String? = nil
    var trailing: String? = nil
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(VDColors.accentTeal)
            }
            Text(title)
                .font(VDTypography.cardTitle)
                .foregroundStyle(VDColors.textPrimary)

            Spacer()

            if let trailing {
                Button {
                    trailingAction?()
                } label: {
                    Text(trailing)
                        .font(VDTypography.caption)
                        .foregroundStyle(VDColors.accentTeal)
                }
            }
        }
        .padding(.horizontal)
    }
}


// MARK: - Ring Progress View

struct VDRingProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    var gradient: LinearGradient = VDColors.gradientScore
    var backgroundColor: Color = VDColors.surfaceTertiary

    var body: some View {
        ZStack {
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(VDAnimation.slow, value: progress)
        }
    }
}


// MARK: - Preview

#Preview {
    ZStack {
        VDColors.background.ignoresSafeArea()

        ScrollView {
            VStack(spacing: VDSpacing.xl) {
                VDSectionHeader(title: "Health Metrics", icon: "heart.fill", trailing: "See All")

                HStack {
                    VDMetricBadge(icon: "heart.fill", label: "HRV", value: "62ms", color: VDColors.heartRed, trend: 8)
                    VDMetricBadge(icon: "moon.fill", label: "Sleep", value: "7.4h", color: VDColors.sleepBlue, trend: -3)
                    VDMetricBadge(icon: "figure.walk", label: "Steps", value: "8.2K", trend: 12)
                }
                .vdCard()

                VDRingProgressView(progress: 0.78, lineWidth: 12)
                    .frame(width: 120, height: 120)
            }
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}
