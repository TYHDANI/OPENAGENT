import SwiftUI

struct AppSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    var onSubmit: (() -> Void)? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundColor(AppColors.textTertiary)

            TextField(placeholder, text: $text)
                .font(AppTypography.body)
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit { onSubmit?() }
                .accessibilityLabel(placeholder)

            if !text.isEmpty {
                Button {
                    AppHaptics.selection()
                    withAnimation(AppAnimation.easeSmooth) {
                        text = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textTertiary)
                }
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .animation(AppAnimation.easeSmooth, value: text.isEmpty)
    }
}
