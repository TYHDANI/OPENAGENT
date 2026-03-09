import SwiftUI

struct WearablesView: View {
    @Environment(WearableAggregatorService.self) private var service
    @State private var searchText = ""
    @State private var filterConnected = false

    private var filteredConnections: [WearableConnection] {
        var result = service.connections
        if filterConnected {
            result = result.filter { $0.status == .connected }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.provider.rawValue.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    private var connectedProviders: [WearableConnection] {
        filteredConnections.filter { $0.status == .connected || $0.status == .syncing }
    }

    private var disconnectedProviders: [WearableConnection] {
        filteredConnections.filter { $0.status != .connected && $0.status != .syncing }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: VDSpacing.xl) {
                    // MARK: - Summary Bar
                    summaryBar

                    // MARK: - Filter Toggle
                    filterBar

                    // MARK: - Connected Providers
                    if !connectedProviders.isEmpty {
                        providerSection(title: "Connected", icon: "checkmark.circle.fill", connections: connectedProviders)
                    }

                    // MARK: - Disconnected Providers
                    if !disconnectedProviders.isEmpty {
                        providerSection(title: "Available", icon: "plus.circle", connections: disconnectedProviders)
                    }
                }
                .padding(.horizontal, VDSpacing.lg)
                .padding(.bottom, VDSpacing.xxxl)
            }
            .background(VDColors.background.ignoresSafeArea())
            .navigationTitle("Wearables")
            .searchable(text: $searchText, prompt: "Search devices...")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        Task { await service.syncAll() }
                    } label: {
                        Group {
                            if service.isLoading {
                                ProgressView()
                                    .tint(VDColors.accentTeal)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                        }
                        .foregroundStyle(VDColors.accentTeal)
                    }
                }
            }
        }
    }

    // MARK: - Summary Bar

    @ViewBuilder
    private var summaryBar: some View {
        HStack(spacing: VDSpacing.lg) {
            summaryItem(
                icon: "antenna.radiowaves.left.and.right",
                value: "\(service.connectedProviderCount)",
                label: "Connected",
                color: VDColors.successGreen
            )

            Divider().frame(height: 32).overlay(VDColors.divider)

            summaryItem(
                icon: "chart.dots.scatter",
                value: abbreviatedCount(service.totalDataPoints),
                label: "Data Points",
                color: VDColors.accentPurple
            )

            Divider().frame(height: 32).overlay(VDColors.divider)

            summaryItem(
                icon: "list.bullet",
                value: "\(WearableProvider.allCases.count)",
                label: "Supported",
                color: VDColors.accentTeal
            )
        }
        .vdCard()
    }

    @ViewBuilder
    private func summaryItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: VDSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)

            Text(value)
                .font(VDTypography.metricSmall)
                .foregroundStyle(VDColors.textPrimary)

            Text(label)
                .font(VDTypography.captionSmall)
                .foregroundStyle(VDColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Filter Bar

    @ViewBuilder
    private var filterBar: some View {
        HStack {
            filterChip(title: "All", isSelected: !filterConnected) {
                withAnimation(VDAnimation.springBounce) { filterConnected = false }
            }
            filterChip(title: "Connected", isSelected: filterConnected) {
                withAnimation(VDAnimation.springBounce) { filterConnected = true }
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(VDTypography.caption)
                .foregroundStyle(isSelected ? VDColors.textInverse : VDColors.textSecondary)
                .padding(.horizontal, VDSpacing.md)
                .padding(.vertical, VDSpacing.sm)
                .background(isSelected ? VDColors.accentTeal : VDColors.surfaceTertiary)
                .clipShape(Capsule())
        }
    }

    // MARK: - Provider Section

    @ViewBuilder
    private func providerSection(title: String, icon: String, connections: [WearableConnection]) -> some View {
        VStack(spacing: VDSpacing.md) {
            VDSectionHeader(title: title, icon: icon)

            ForEach(connections) { connection in
                ProviderCard(connection: connection)
            }
        }
    }

    private func abbreviatedCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        }
        return "\(count)"
    }
}

// MARK: - Provider Card

struct ProviderCard: View {
    @Environment(WearableAggregatorService.self) private var service
    let connection: WearableConnection
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Main Row
            HStack(spacing: VDSpacing.md) {
                // Provider Icon
                Image(systemName: connection.provider.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(connection.provider.color)
                    .frame(width: 44, height: 44)
                    .background(connection.provider.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: VDRadius.md, style: .continuous))

                // Provider Info
                VStack(alignment: .leading, spacing: VDSpacing.xxs) {
                    Text(connection.provider.rawValue)
                        .font(VDTypography.bodyBold)
                        .foregroundStyle(VDColors.textPrimary)

                    HStack(spacing: VDSpacing.xs) {
                        Circle()
                            .fill(connection.status.color)
                            .frame(width: 6, height: 6)

                        Text(connection.status.label)
                            .font(VDTypography.captionSmall)
                            .foregroundStyle(connection.status.color)

                        if connection.status == .connected, let lastSync = connection.lastSyncAt {
                            Text("synced \(lastSync, format: .relative(presentation: .named))")
                                .font(VDTypography.captionSmall)
                                .foregroundStyle(VDColors.textTertiary)
                        }
                    }
                }

                Spacer()

                // Data Points Badge
                if connection.dataPointCount > 0 {
                    Text(abbreviatedCount(connection.dataPointCount))
                        .font(VDTypography.captionSmall)
                        .foregroundStyle(VDColors.textSecondary)
                        .padding(.horizontal, VDSpacing.sm)
                        .padding(.vertical, VDSpacing.xs)
                        .background(VDColors.surfaceTertiary)
                        .clipShape(Capsule())
                }

                // Connect/Disconnect Button
                connectButton
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(VDAnimation.springSmooth) {
                    isExpanded.toggle()
                }
            }

            // Expanded: Supported Metrics
            if isExpanded {
                expandedContent
            }
        }
        .vdCard(padding: VDSpacing.md)
    }

    @ViewBuilder
    private var connectButton: some View {
        Button {
            Task {
                if connection.status == .connected {
                    service.disconnectProvider(connection.provider)
                } else {
                    await service.connectProvider(connection.provider)
                }
            }
        } label: {
            Group {
                if connection.status == .syncing {
                    ProgressView()
                        .tint(VDColors.accentTeal)
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: connection.status == .connected ? "xmark.circle" : "plus.circle.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(connection.status == .connected ? VDColors.heartRed.opacity(0.7) : VDColors.accentTeal)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: VDSpacing.sm) {
            Divider().overlay(VDColors.divider)
                .padding(.vertical, VDSpacing.sm)

            Text("Supported Metrics")
                .font(VDTypography.caption)
                .foregroundStyle(VDColors.textSecondary)

            FlowLayout(spacing: VDSpacing.sm) {
                ForEach(connection.provider.supportedMetrics) { metric in
                    HStack(spacing: VDSpacing.xs) {
                        Image(systemName: metric.icon)
                            .font(.system(size: 10, weight: .medium))
                        Text(metric.rawValue)
                            .font(VDTypography.captionSmall)
                    }
                    .foregroundStyle(metric.color)
                    .padding(.horizontal, VDSpacing.sm)
                    .padding(.vertical, VDSpacing.xs)
                    .background(metric.color.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            // Auth Type
            HStack(spacing: VDSpacing.xs) {
                Image(systemName: connection.provider.authType == .sdk ? "iphone" : "lock.shield")
                    .font(.system(size: 11, weight: .medium))
                Text(connection.provider.authType == .sdk ? "On-device SDK" : "OAuth 2.0")
                    .font(VDTypography.captionSmall)
            }
            .foregroundStyle(VDColors.textTertiary)
            .padding(.top, VDSpacing.xs)
        }
    }

    private func abbreviatedCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        }
        return "\(count)"
    }
}

// MARK: - Flow Layout (for metric tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> ArrangementResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            sizes.append(size)
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return ArrangementResult(
            positions: positions,
            sizes: sizes,
            size: CGSize(width: maxWidth, height: y + rowHeight)
        )
    }

    struct ArrangementResult {
        var positions: [CGPoint]
        var sizes: [CGSize]
        var size: CGSize
    }
}

#Preview {
    WearablesView()
        .environment(WearableAggregatorService())
        .preferredColorScheme(.dark)
}
