import SwiftUI

struct AlertsCenterView: View {
    @Bindable var viewModel: AlertsViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.filteredAlerts.isEmpty {
                    ContentUnavailableView(
                        "No Alerts",
                        systemImage: "bell.slash",
                        description: Text("Score changes and risk alerts will appear here.")
                    )
                } else {
                    List {
                        // Summary header
                        if viewModel.alertService.unreadCount > 0 {
                            Section {
                                HStack(spacing: 16) {
                                    AlertCountBadge(count: viewModel.criticalCount, severity: .critical)
                                    AlertCountBadge(count: viewModel.moderateCount, severity: .moderate)
                                    AlertCountBadge(count: viewModel.infoCount, severity: .info)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                            }
                        }

                        // Severity filter
                        Section {
                            Picker("Filter", selection: $viewModel.selectedSeverity) {
                                Text("All").tag(AlertSeverity?.none)
                                ForEach(AlertSeverity.allCases, id: \.self) { severity in
                                    Text(severity.rawValue).tag(Optional(severity))
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // Alert list
                        Section {
                            ForEach(viewModel.filteredAlerts) { alert in
                                AlertRowView(alert: alert)
                                    .onTapGesture {
                                        viewModel.markAsRead(alert.id)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            viewModel.deleteAlert(alert.id)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Alerts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Mark All as Read", systemImage: "checkmark.circle") {
                            viewModel.markAllAsRead()
                        }
                        .disabled(!viewModel.hasUnread)

                        Button("Enable Notifications", systemImage: "bell.badge") {
                            viewModel.requestNotifications()
                        }

                        Divider()

                        Button("Clear All", systemImage: "trash", role: .destructive) {
                            viewModel.clearAll()
                        }
                        .disabled(viewModel.filteredAlerts.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

// MARK: - Alert Row

private struct AlertRowView: View {
    let alert: AlertItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: alert.severity.systemImage)
                .foregroundStyle(severityColor(alert.severity))
                .font(.title3)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alert.title)
                        .font(.subheadline.bold())
                        .lineLimit(2)

                    if !alert.isRead {
                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                    }
                }

                Text(alert.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                HStack {
                    if let prev = alert.previousScore, let curr = alert.currentScore {
                        Text("\(prev) → \(curr)")
                            .font(.caption2.bold().monospaced())
                            .foregroundStyle(curr < prev ? .red : .green)
                    }

                    Spacer()

                    Text(alert.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(alert.isRead ? 0.7 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(alert.severity.rawValue) alert: \(alert.title)")
    }
}

// MARK: - Alert Count Badge

private struct AlertCountBadge: View {
    let count: Int
    let severity: AlertSeverity

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title3.bold())
                .foregroundStyle(severityColor(severity))
            Text(severity.rawValue)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Helpers

private func severityColor(_ severity: AlertSeverity) -> Color {
    switch severity {
    case .critical: return .red
    case .moderate: return .orange
    case .info: return .blue
    }
}
