import SwiftUI

struct ScoreGaugeView: View {
    let score: Int
    let size: CGFloat

    private var progress: Double {
        Double(score) / 100.0
    }

    private var scoreColor: Color {
        colorForScore(score)
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(scoreColor.opacity(0.2), lineWidth: size * 0.1)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    scoreColor,
                    style: StrokeStyle(
                        lineWidth: size * 0.1,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            // Score text
            Text("\(score)")
                .font(.system(size: size * 0.32, weight: .bold, design: .rounded))
                .foregroundStyle(scoreColor)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Score \(score) out of 100")
    }
}
