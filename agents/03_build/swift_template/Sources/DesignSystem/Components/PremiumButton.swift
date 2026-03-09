import SwiftUI

enum PremiumButtonStyle {
    case primary, secondary, ghost
}

struct PremiumButton: View {
    let title: String
    var icon: String? = nil
    var style: PremiumButtonStyle = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            AppHaptics.impact(.light)
            action()
        } label: {
            HStack(spacing: AppSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(style == .primary ? .white : AppColors.accent)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.body.weight(.semibold))
                    }
                    Text(title)
                        .font(AppTypography.bodyBold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm)
            .background(backgroundForStyle)
            .foregroundColor(foregroundForStyle)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(overlayForStyle)
        }
        .disabled(isLoading || isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(AppAnimation.springSnappy, value: isPressed)
    }

    @ViewBuilder
    private var backgroundForStyle: some View {
        switch style {
        case .primary:
            AppColors.accent
        case .secondary:
            AppColors.accentLight
        case .ghost:
            Color.clear
        }
    }

    private var foregroundForStyle: Color {
        switch style {
        case .primary: return .white
        case .secondary: return AppColors.accent
        case .ghost: return AppColors.accent
        }
    }

    @ViewBuilder
    private var overlayForStyle: some View {
        switch style {
        case .secondary:
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(AppColors.accent.opacity(0.3), lineWidth: 1)
        default:
            EmptyView()
        }
    }
}
