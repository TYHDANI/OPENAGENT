import SwiftUI

enum BadgeStyle {
    case `default`, success, warning, error, premium

    var foreground: Color {
        switch self {
        case .default: return AppColors.textSecondary
        case .success: return AppColors.success
        case .warning: return AppColors.warning
        case .error: return AppColors.error
        case .premium: return AppColors.accent
        }
    }

    var background: Color {
        foreground.opacity(0.12)
    }
}

struct BadgeView: View {
    let text: String
    var icon: String? = nil
    var style: BadgeStyle = .default

    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(AppTypography.badge)
        }
        .foregroundColor(style.foreground)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xxs)
        .background(style.background)
        .clipShape(Capsule())
    }
}
