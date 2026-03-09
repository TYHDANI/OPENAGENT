import SwiftUI

struct ShimmerView: View {
    var width: CGFloat? = nil
    var height: CGFloat = 20
    var cornerRadius: CGFloat = AppRadius.sm

    @State private var phase: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(AppColors.divider.opacity(0.3))
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: phase * 200)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

struct ShimmerCard: View {
    var lines: Int = 3

    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ShimmerView(width: 120, height: 14)
                ForEach(0..<lines, id: \.self) { i in
                    ShimmerView(
                        width: i == lines - 1 ? 180 : nil,
                        height: 12
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ShimmerList: View {
    var count: Int = 5

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(0..<count, id: \.self) { _ in
                ShimmerCard(lines: 2)
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }
}
