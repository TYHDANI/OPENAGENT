import SwiftUI

struct PremiumCard<Content: View>: View {
    let content: Content
    var material: Bool = false
    var isHighlighted: Bool = false
    var padding: CGFloat = AppSpacing.md

    init(material: Bool = false, isHighlighted: Bool = false, padding: CGFloat = AppSpacing.md, @ViewBuilder content: () -> Content) {
        self.material = material
        self.isHighlighted = isHighlighted
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        Group {
            if material {
                content
                    .padding(padding)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                    .appShadow(AppShadow.md)
            } else {
                content
                    .padding(padding)
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                            .stroke(isHighlighted ? AppColors.accent : Color.clear, lineWidth: 2)
                    )
                    .appShadow(isHighlighted ? AppShadow.md : AppShadow.sm)
            }
        }
        .animation(AppAnimation.springSnappy, value: isHighlighted)
    }
}
