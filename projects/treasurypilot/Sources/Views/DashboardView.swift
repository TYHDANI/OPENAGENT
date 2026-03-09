import SwiftUI

struct DashboardView: View {
    @Environment(EntityViewModel.self) private var entityVM
    @Environment(TransactionViewModel.self) private var transactionVM
    @Environment(TaxViewModel.self) private var taxVM

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TPTheme.sectionSpacing) {
                    // Hero Portfolio Summary
                    heroSummaryCard

                    // Portfolio Mini-Chart Placeholder
                    portfolioChartCard

                    // Tax Alert Banner
                    if !taxVM.washSaleAlerts.isEmpty {
                        washSaleWarning
                    }

                    // Stat Grid
                    statGrid

                    // Entities Overview
                    entitiesSection

                    // Recent Transactions
                    recentTransactionsSection
                }
                .padding(TPTheme.paddingStandard)
            }
            .background(TPTheme.background.ignoresSafeArea())
            .navigationTitle("TreasuryPilot")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await entityVM.load()
                await transactionVM.load()
                await taxVM.load()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Hero Summary

    private var heroSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Portfolio Overview")
                .font(TPTheme.caption())
                .foregroundStyle(TPTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(1.2)

            Text(formatCurrency(transactionVM.totalValue(for: nil)))
                .font(TPTheme.heading(34))
                .foregroundStyle(TPTheme.goldGradient)
                .contentTransition(.numericText())

            HStack(spacing: 6) {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 11))
                Text("\(entityVM.entities.count) entities")
                Text("·")
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 11))
                Text("\(entityVM.accounts.count) accounts")
            }
            .font(TPTheme.caption())
            .foregroundStyle(TPTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .goldGlassCard()
    }

    // MARK: - Portfolio Chart Placeholder

    private var portfolioChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            TPSectionHeader(title: "Portfolio Value", icon: "chart.line.uptrend.xyaxis", trailing: "30D")

            // Placeholder chart area
            ZStack {
                // Simulated mini line-chart background
                GeometryReader { geo in
                    Path { path in
                        let w = geo.size.width
                        let h = geo.size.height
                        let points: [CGFloat] = [0.6, 0.5, 0.55, 0.45, 0.5, 0.42, 0.48, 0.35, 0.4, 0.32, 0.28, 0.3]
                        let stepX = w / CGFloat(points.count - 1)

                        path.move(to: CGPoint(x: 0, y: h * points[0]))
                        for (i, pt) in points.enumerated() {
                            path.addLine(to: CGPoint(x: stepX * CGFloat(i), y: h * pt))
                        }
                    }
                    .stroke(TPTheme.gold.opacity(0.8), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                    // Fill under the line
                    Path { path in
                        let w = geo.size.width
                        let h = geo.size.height
                        let points: [CGFloat] = [0.6, 0.5, 0.55, 0.45, 0.5, 0.42, 0.48, 0.35, 0.4, 0.32, 0.28, 0.3]
                        let stepX = w / CGFloat(points.count - 1)

                        path.move(to: CGPoint(x: 0, y: h))
                        path.addLine(to: CGPoint(x: 0, y: h * points[0]))
                        for (i, pt) in points.enumerated() {
                            path.addLine(to: CGPoint(x: stepX * CGFloat(i), y: h * pt))
                        }
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [TPTheme.gold.opacity(0.25), TPTheme.gold.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 100)

                if entityVM.entities.isEmpty {
                    Text("Add entities to see portfolio trends")
                        .font(TPTheme.caption())
                        .foregroundStyle(TPTheme.textTertiary)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Stat Grid

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ThemedStatCard(
                title: "Entities",
                value: "\(entityVM.entities.count)",
                icon: "building.2.fill",
                accentColor: TPTheme.accentSecondary
            )
            ThemedStatCard(
                title: "Accounts",
                value: "\(entityVM.accounts.count)",
                icon: "link.circle.fill",
                accentColor: TPTheme.success
            )
            ThemedStatCard(
                title: "Cost Basis",
                value: formatCurrency(transactionVM.totalValue(for: nil)),
                icon: "dollarsign.circle.fill",
                accentColor: TPTheme.gold
            )
            ThemedStatCard(
                title: "Est. Tax",
                value: formatCurrency(taxVM.totalEstimatedTax(for: nil)),
                icon: "doc.text.fill",
                accentColor: TPTheme.danger
            )
        }
    }

    // MARK: - Wash Sale Warning

    private var washSaleWarning: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18))
                .foregroundStyle(TPTheme.warning)
            VStack(alignment: .leading, spacing: 2) {
                Text("Wash Sale Alert")
                    .font(TPTheme.subheading(14))
                    .foregroundStyle(TPTheme.textPrimary)
                Text("\(taxVM.washSaleAlerts.count) potential violation\(taxVM.washSaleAlerts.count == 1 ? "" : "s") detected")
                    .font(TPTheme.caption())
                    .foregroundStyle(TPTheme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(TPTheme.textTertiary)
        }
        .padding(TPTheme.paddingStandard)
        .background(
            RoundedRectangle(cornerRadius: TPTheme.cornerRadius)
                .fill(TPTheme.warning.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: TPTheme.cornerRadius)
                        .stroke(TPTheme.warning.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Entities Section

    private var entitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TPSectionHeader(
                title: "Entities",
                icon: "building.2",
                trailing: entityVM.entities.isEmpty ? nil : "\(entityVM.entities.count)"
            )

            if entityVM.entities.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "building.2")
                        .font(.system(size: 32))
                        .foregroundStyle(TPTheme.textTertiary)
                    Text("No Entities Yet")
                        .font(TPTheme.subheading())
                        .foregroundStyle(TPTheme.textSecondary)
                    Text("Add your first legal entity to get started.")
                        .font(TPTheme.caption())
                        .foregroundStyle(TPTheme.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .glassCard()
            } else {
                ForEach(entityVM.entities) { entity in
                    NavigationLink(value: entity) {
                        ThemedEntityRow(
                            entity: entity,
                            accountCount: entityVM.accounts(for: entity.id).count
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationDestination(for: LegalEntity.self) { entity in
            EntityDetailView(entity: entity)
        }
    }

    // MARK: - Recent Transactions Section

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TPSectionHeader(title: "Recent Transactions", icon: "clock.arrow.circlepath")

            if transactionVM.transactions.isEmpty {
                HStack {
                    Image(systemName: "tray")
                        .foregroundStyle(TPTheme.textTertiary)
                    Text("No transactions yet")
                        .font(TPTheme.body())
                        .foregroundStyle(TPTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(transactionVM.transactions.prefix(5).sorted(by: { $0.date > $1.date }).enumerated()), id: \.element.id) { index, tx in
                        ThemedTransactionRow(transaction: tx)
                        if index < min(4, transactionVM.transactions.count - 1) {
                            TPDivider()
                                .padding(.horizontal, TPTheme.paddingStandard)
                        }
                    }
                }
                .glassCard(padding: 0)
            }
        }
    }

    // MARK: - Helpers

    private func formatCurrency(_ value: Double) -> String {
        ReportGenerator.formatCurrency(value)
    }
}

// MARK: - Themed Stat Card

struct ThemedStatCard: View {
    let title: String
    let value: String
    let icon: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accentColor)
                Text(title)
                    .font(TPTheme.caption())
                    .foregroundStyle(TPTheme.textSecondary)
            }
            Text(value)
                .font(TPTheme.heading(20))
                .foregroundStyle(TPTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: TPTheme.paddingCompact)
    }
}

// MARK: - Themed Entity Row

struct ThemedEntityRow: View {
    let entity: LegalEntity
    let accountCount: Int

    var body: some View {
        HStack(spacing: 12) {
            // Icon circle with gold accent
            ZStack {
                Circle()
                    .fill(TPTheme.gold.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: entity.entityType.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(TPTheme.gold)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(entity.name)
                    .font(TPTheme.subheading())
                    .foregroundStyle(TPTheme.textPrimary)
                HStack(spacing: 6) {
                    Text(entity.entityType.rawValue)
                    Text("·")
                    Text(entity.costBasisMethod.rawValue)
                    Text("·")
                    Text("\(accountCount) acct\(accountCount == 1 ? "" : "s")")
                }
                .font(TPTheme.caption())
                .foregroundStyle(TPTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(TPTheme.textTertiary)
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entity.name), \(entity.entityType.rawValue), \(accountCount) accounts")
    }
}

// MARK: - Themed Transaction Row

struct ThemedTransactionRow: View {
    let transaction: CryptoTransaction

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(colorForType.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: transaction.transactionType.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(colorForType)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(transaction.transactionType.rawValue)
                        .font(TPTheme.subheading(14))
                        .foregroundStyle(TPTheme.textPrimary)
                    Text(transaction.asset)
                        .font(TPTheme.caption())
                        .foregroundStyle(TPTheme.textSecondary)
                }
                Text(transaction.date, style: .date)
                    .font(TPTheme.caption(11))
                    .foregroundStyle(TPTheme.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.6f", transaction.quantity))
                    .font(TPTheme.mono(13))
                    .foregroundStyle(TPTheme.textPrimary)
                Text(ReportGenerator.formatCurrency(transaction.totalValue))
                    .font(TPTheme.caption(11))
                    .foregroundStyle(TPTheme.textSecondary)
            }
        }
        .padding(.horizontal, TPTheme.paddingStandard)
        .padding(.vertical, TPTheme.paddingCompact)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(transaction.transactionType.rawValue) \(String(format: "%.6f", transaction.quantity)) \(transaction.asset)")
    }

    private var colorForType: Color {
        switch transaction.transactionType {
        case .buy: return TPTheme.success
        case .sell: return TPTheme.danger
        case .transfer: return TPTheme.accentSecondary
        case .income: return TPTheme.gold
        case .fee: return TPTheme.textSecondary
        }
    }
}

// MARK: - Legacy StatCard (kept for backward compat)

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        ThemedStatCard(title: title, value: value, icon: icon, accentColor: color)
    }
}

// MARK: - Legacy EntityRowView (kept for backward compat)

struct EntityRowView: View {
    let entity: LegalEntity
    let accountCount: Int

    var body: some View {
        ThemedEntityRow(entity: entity, accountCount: accountCount)
    }
}

// MARK: - Legacy TransactionRowView (kept for backward compat)

struct TransactionRowView: View {
    let transaction: CryptoTransaction

    var body: some View {
        ThemedTransactionRow(transaction: transaction)
    }
}
