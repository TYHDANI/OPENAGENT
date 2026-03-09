import SwiftUI

struct LayerToggle: View {
    let layer: DataLayerType
    @Binding var isActive: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                isActive.toggle()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: layer.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(isActive ? layer.color : NETheme.textTertiary)
                    .frame(width: 28, height: 28)
                    .background(isActive ? layer.color.opacity(0.15) : NETheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(layer.rawValue)
                    .font(NETheme.body(13))
                    .foregroundStyle(isActive ? NETheme.textPrimary : NETheme.textSecondary)

                Spacer()

                Circle()
                    .fill(isActive ? layer.color : NETheme.textTertiary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isActive ? layer.color.opacity(0.05) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(layer.rawValue) layer \(isActive ? "active" : "inactive")")
        .sensoryFeedback(.selection, trigger: isActive)
    }
}

struct MagnitudeIndicator: View {
    let magnitude: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(magnitudeColor.opacity(0.3))
                .frame(width: outerSize, height: outerSize)
            Circle()
                .fill(magnitudeColor.opacity(0.7))
                .frame(width: innerSize, height: innerSize)
            Text(String(format: "%.1f", magnitude))
                .font(NETheme.mono(max(8, innerSize * 0.4)))
                .foregroundStyle(.white)
        }
    }

    private var outerSize: CGFloat { max(20, magnitude * 8) }
    private var innerSize: CGFloat { max(14, magnitude * 5) }

    private var magnitudeColor: Color {
        switch magnitude {
        case ..<3: return NETheme.severityLow
        case 3..<5: return NETheme.severityMedium
        case 5..<7: return NETheme.severityHigh
        default: return NETheme.severityCritical
        }
    }
}

struct FeedStatusIndicator: View {
    let name: String
    let count: Int
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color)
            Text("\(count)")
                .font(NETheme.mono(11))
                .foregroundStyle(NETheme.textPrimary)
            Text(name)
                .font(NETheme.caption(10))
                .foregroundStyle(NETheme.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.08))
        .clipShape(Capsule())
    }
}
