import SwiftUI

struct AlertsTab: View {
    @Environment(DataOrchestrator.self) private var data

    var body: some View {
        NavigationStack {
            ZStack {
                NETheme.background.ignoresSafeArea()

                if data.alerts.isEmpty {
                    ContentUnavailableView(
                        "No Breaking Alerts",
                        systemImage: "bell.slash",
                        description: Text("You'll be notified when critical events are detected across intelligence feeds")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(data.alerts) { alert in
                                AlertCard(alert: alert)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Alerts")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        // Refresh
                        Task { await data.startAllFeeds() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(NETheme.accent)
                    }
                }
            }
        }
    }
}

struct AlertCard: View {
    let alert: BreakingAlert

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: alert.category.icon)
                    .foregroundStyle(Color(hex: alert.severity.colorHex))
                    .frame(width: 28, height: 28)
                    .background(Color(hex: alert.severity.colorHex).opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(alert.category.rawValue.uppercased())
                        .font(NETheme.mono(9))
                        .foregroundStyle(NETheme.textTertiary)
                    Text(alert.title)
                        .font(NETheme.subheading(15))
                        .foregroundStyle(NETheme.textPrimary)
                }

                Spacer()

                SeverityBadge(level: alert.severity)
            }

            Text(alert.description)
                .font(NETheme.body(13))
                .foregroundStyle(NETheme.textSecondary)

            HStack {
                Label(alert.source, systemImage: "antenna.radiowaves.left.and.right")
                Spacer()
                Text(alert.timeAgo)
            }
            .font(NETheme.caption())
            .foregroundStyle(NETheme.textTertiary)
        }
        .padding()
        .glassCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: alert.severity.colorHex).opacity(0.3), lineWidth: 1)
        )
    }
}
