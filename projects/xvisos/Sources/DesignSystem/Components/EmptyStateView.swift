import SwiftUI

struct AppEmptyStateView: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    @State private var animate = false

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(AppColors.accent.opacity(0.6))
                .symbolEffect(.bounce, value: animate)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        animate = true
                    }
                }

            VStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.sectionTitle)
                    .foregroundColor(AppColors.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            if let actionTitle, let action {
                PremiumButton(title: actionTitle, style: .secondary, action: action)
                    .frame(maxWidth: 220)
            }
        }
        .padding(AppSpacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
