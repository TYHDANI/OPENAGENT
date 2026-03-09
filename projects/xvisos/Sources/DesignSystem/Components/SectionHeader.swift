import SwiftUI

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(AppTypography.sectionTitle)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            if let trailing, let action {
                Button {
                    AppHaptics.selection()
                    action()
                } label: {
                    Text(trailing)
                        .font(AppTypography.callout)
                        .foregroundColor(AppColors.accent)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
    }
}
