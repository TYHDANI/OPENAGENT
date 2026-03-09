import SwiftUI

struct TimelineScrubber: View {
    @Environment(AppState.self) private var appState
    @State private var scrubPosition: Double = 1.0

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(timeLabel(for: 0))
                    .font(NETheme.mono(9))
                    .foregroundStyle(NETheme.textTertiary)
                Spacer()
                HStack(spacing: 8) {
                    Button { scrubPosition = max(0, scrubPosition - 0.1) } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 10))
                    }

                    Button {
                        appState.isTimelinePlaying.toggle()
                    } label: {
                        Image(systemName: appState.isTimelinePlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 12))
                    }

                    Button { scrubPosition = min(1.0, scrubPosition + 0.1) } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 10))
                    }
                }
                .foregroundStyle(NETheme.accent)
                Spacer()
                Text("Now")
                    .font(NETheme.mono(9))
                    .foregroundStyle(NETheme.accent)
            }

            // Scrubber
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(NETheme.surfaceOverlay)
                        .frame(height: 4)

                    // Fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [NETheme.accent.opacity(0.5), NETheme.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * scrubPosition, height: 4)

                    // Thumb
                    Circle()
                        .fill(NETheme.accent)
                        .frame(width: 14, height: 14)
                        .shadow(color: NETheme.accent.opacity(0.5), radius: 4)
                        .offset(x: geo.size.width * scrubPosition - 7)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    scrubPosition = max(0, min(1, value.location.x / geo.size.width))
                                    let hours = 24.0 * (1.0 - scrubPosition)
                                    appState.timelinePosition = Date().addingTimeInterval(-hours * 3600)
                                }
                        )
                }
            }
            .frame(height: 14)

            // Time markers
            HStack {
                Text("-24h")
                Spacer()
                Text("-18h")
                Spacer()
                Text("-12h")
                Spacer()
                Text("-6h")
                Spacer()
                Text("Now")
            }
            .font(NETheme.mono(8))
            .foregroundStyle(NETheme.textTertiary)
        }
        .padding(12)
        .glassCard(cornerRadius: 12)
    }

    private func timeLabel(for position: Double) -> String {
        let hours = Int(24 * (1.0 - position))
        if hours == 0 { return "Now" }
        return "-\(hours)h"
    }
}
