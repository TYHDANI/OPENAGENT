import SwiftUI

struct SmartMoneyTab: View {
    @Environment(DataOrchestrator.self) private var data
    @State private var selectedSection: SmartMoneySection = .cascade

    enum SmartMoneySection: String, CaseIterable {
        case cascade = "Cascade"
        case signals = "Signals"
        case trades = "Trades"
        case contracts = "Contracts"
        case lobbying = "Lobbying"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NETheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Section Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(SmartMoneySection.allCases, id: \.self) { section in
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedSection = section
                                    }
                                } label: {
                                    Text(section.rawValue)
                                        .font(NETheme.body(13))
                                        .foregroundStyle(selectedSection == section ? .black : NETheme.textSecondary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(selectedSection == section ? NETheme.accent : NETheme.surfaceOverlay)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)

                    switch selectedSection {
                    case .cascade:
                        CascadeView()
                    case .signals:
                        SectorSignalsView()
                    case .trades:
                        PoliticianTradesView()
                    case .contracts:
                        ContractsView()
                    case .lobbying:
                        LobbyingView()
                    }
                }
            }
            .navigationTitle("Smart Money")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await data.refreshCapitalFlows() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(NETheme.accent)
                    }
                }
            }
        }
    }
}

// MARK: - Cascade Timeline View
struct CascadeView: View {
    @Environment(DataOrchestrator.self) private var data

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Cascade Phase Timeline
                VStack(alignment: .leading, spacing: 4) {
                    Text("CAPITAL FLOW CASCADE")
                        .font(NETheme.mono(10))
                        .foregroundStyle(NETheme.textTertiary)
                    Text("Track political money through the system")
                        .font(NETheme.body(13))
                        .foregroundStyle(NETheme.textSecondary)
                }
                .padding(.horizontal)

                // Phase cards
                ForEach(CascadePhase.allCases, id: \.rawValue) { phase in
                    CascadePhaseCard(
                        phase: phase,
                        signalCount: data.sectorSignals.filter { $0.cascadePhase == phase }.count,
                        isActive: currentPhaseMatches(phase)
                    )
                }

                // Key Metrics Row
                HStack(spacing: 12) {
                    MetricCard(
                        title: "Politicians Trading",
                        value: "\(uniquePoliticianCount)",
                        icon: "person.2.fill",
                        color: NETheme.accentSecondary
                    )
                    MetricCard(
                        title: "Sectors Active",
                        value: "\(data.sectorSignals.count)",
                        icon: "chart.bar.fill",
                        color: NETheme.accent
                    )
                }
                .padding(.horizontal)

                HStack(spacing: 12) {
                    MetricCard(
                        title: "Contracts",
                        value: "\(data.recentContracts.count)",
                        icon: "doc.text.fill",
                        color: Color(hex: "#FF9800")
                    )
                    MetricCard(
                        title: "Lobbying Filings",
                        value: "\(data.lobbyingFilings.count)",
                        icon: "building.columns.fill",
                        color: Color(hex: "#CE93D8")
                    )
                }
                .padding(.horizontal)

                // National Debt Ticker
                if data.nationalDebt > 0 {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NATIONAL DEBT")
                            .font(NETheme.mono(10))
                            .foregroundStyle(NETheme.textTertiary)
                        Text(formatDebt(data.nationalDebt))
                            .font(.system(size: 28, weight: .thin, design: .monospaced))
                            .foregroundStyle(NETheme.severityCritical)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .glassCard()
                    .padding(.horizontal)
                }

                // Job Openings Trend
                if !data.jobOpenings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("JOB OPENINGS (JOLTS)")
                            .font(NETheme.mono(10))
                            .foregroundStyle(NETheme.textTertiary)

                        HStack(alignment: .bottom, spacing: 3) {
                            ForEach(data.jobOpenings.suffix(12), id: \.0) { period, value in
                                VStack(spacing: 2) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(NETheme.accent.opacity(0.7))
                                        .frame(width: 16, height: barHeight(value))
                                    Text(String(period.suffix(3)))
                                        .font(NETheme.mono(7))
                                        .foregroundStyle(NETheme.textTertiary)
                                        .rotationEffect(.degrees(-45))
                                }
                            }
                        }
                        .frame(height: 120)
                    }
                    .padding()
                    .glassCard()
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    private var uniquePoliticianCount: Int {
        Set((data.houseTrades + data.senateTrades).map { $0.memberName }).count
    }

    private func currentPhaseMatches(_ phase: CascadePhase) -> Bool {
        data.sectorSignals.contains { $0.cascadePhase == phase }
    }

    private func formatDebt(_ amount: Double) -> String {
        let trillion = amount / 1_000_000_000_000
        return String(format: "$%.3fT", trillion)
    }

    private func barHeight(_ value: Double) -> CGFloat {
        let maxVal = data.jobOpenings.map(\.1).max() ?? 1
        return CGFloat(value / maxVal) * 80
    }
}

struct CascadePhaseCard: View {
    let phase: CascadePhase
    let signalCount: Int
    let isActive: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Phase indicator
            VStack(spacing: 0) {
                Circle()
                    .fill(isActive ? Color(hex: phase.color) : NETheme.surfaceOverlay)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("\(phase.rawValue)")
                            .font(NETheme.mono(12))
                            .foregroundStyle(isActive ? .white : NETheme.textTertiary)
                    )
                if phase != .budgetUnlock {
                    Rectangle()
                        .fill(isActive ? Color(hex: phase.color).opacity(0.4) : NETheme.surfaceOverlay)
                        .frame(width: 2, height: 20)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(phase.shortLabel.uppercased())
                    .font(NETheme.mono(10))
                    .foregroundStyle(isActive ? Color(hex: phase.color) : NETheme.textTertiary)

                Text(phase.label)
                    .font(NETheme.subheading(14))
                    .foregroundStyle(isActive ? NETheme.textPrimary : NETheme.textSecondary)

                Text(phase.description)
                    .font(NETheme.body(12))
                    .foregroundStyle(NETheme.textTertiary)

                if signalCount > 0 {
                    Text("\(signalCount) active signals")
                        .font(NETheme.mono(10))
                        .foregroundStyle(Color(hex: phase.color))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: phase.color).opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
                Text(title)
                    .font(NETheme.caption(10))
                    .foregroundStyle(NETheme.textTertiary)
            }
            Text(value)
                .font(.system(size: 24, weight: .semibold, design: .monospaced))
                .foregroundStyle(NETheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard()
    }
}

// MARK: - Sector Signals View
struct SectorSignalsView: View {
    @Environment(DataOrchestrator.self) private var data

    var body: some View {
        ScrollView {
            if data.sectorSignals.isEmpty {
                ContentUnavailableView(
                    "Analyzing Signals",
                    systemImage: "antenna.radiowaves.left.and.right",
                    description: Text("Cross-referencing politician trades, contracts, and lobbying data")
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(data.sectorSignals) { signal in
                        SectorSignalCard(signal: signal)
                    }
                }
                .padding()
            }
        }
    }
}

struct SectorSignalCard: View {
    let signal: SectorSignal

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(signal.sector)
                        .font(NETheme.heading(18))
                        .foregroundStyle(NETheme.textPrimary)
                    Text(signal.cascadePhase.shortLabel)
                        .font(NETheme.mono(10))
                        .foregroundStyle(Color(hex: signal.cascadePhase.color))
                }
                Spacer()
                // Opportunity Score
                ZStack {
                    Circle()
                        .stroke(Color(hex: signal.signalStrength.color).opacity(0.3), lineWidth: 3)
                        .frame(width: 48, height: 48)
                    Circle()
                        .trim(from: 0, to: signal.opportunityScore / 100)
                        .stroke(Color(hex: signal.signalStrength.color), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 48, height: 48)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(signal.opportunityScore))")
                        .font(NETheme.mono(14))
                        .foregroundStyle(Color(hex: signal.signalStrength.color))
                }
            }

            // Signal Strength
            HStack(spacing: 8) {
                Image(systemName: signal.signalStrength.icon)
                    .foregroundStyle(Color(hex: signal.signalStrength.color))
                Text(signal.signalStrength.rawValue)
                    .font(NETheme.mono(11))
                    .foregroundStyle(Color(hex: signal.signalStrength.color))

                Text(signal.trendDirection.rawValue)
                    .font(NETheme.caption())
                    .foregroundStyle(NETheme.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(NETheme.surfaceOverlay)
                    .clipShape(Capsule())
            }

            // Stats row
            HStack(spacing: 16) {
                StatPill(label: "Buys", value: "\(signal.politicianBuyCount)", color: NETheme.severityLow)
                StatPill(label: "Sells", value: "\(signal.politicianSellCount)", color: NETheme.severityCritical)
                StatPill(label: "Volume", value: formatCompact(signal.totalPoliticianVolume), color: NETheme.accent)
            }

            // Top Politicians
            if !signal.topPoliticians.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("KEY PLAYERS")
                        .font(NETheme.mono(9))
                        .foregroundStyle(NETheme.textTertiary)
                    FlowLayout(spacing: 4) {
                        ForEach(signal.topPoliticians, id: \.self) { name in
                            Text(name)
                                .font(NETheme.caption(10))
                                .foregroundStyle(NETheme.accentSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(NETheme.accentSecondary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding()
        .glassCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: signal.signalStrength.color).opacity(0.2), lineWidth: 1)
        )
    }

    private func formatCompact(_ value: Double) -> String {
        if value >= 1_000_000 { return String(format: "$%.1fM", value / 1_000_000) }
        if value >= 1_000 { return String(format: "$%.0fK", value / 1_000) }
        return String(format: "$%.0f", value)
    }
}

struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(NETheme.mono(12))
                .foregroundStyle(color)
            Text(label)
                .font(NETheme.caption(9))
                .foregroundStyle(NETheme.textTertiary)
        }
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, point) in result.origins.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var origins: [CGPoint] = []
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
            origins.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), origins)
    }
}

// MARK: - Politician Trades View
struct PoliticianTradesView: View {
    @Environment(DataOrchestrator.self) private var data
    @State private var chamber: Chamber = .all

    enum Chamber: String, CaseIterable {
        case all = "All"
        case house = "House"
        case senate = "Senate"
    }

    var filteredTrades: [CongressTrade] {
        let allTrades = data.houseTrades + data.senateTrades
        switch chamber {
        case .all: return allTrades
        case .house: return data.houseTrades
        case .senate: return data.senateTrades
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Chamber filter
            Picker("Chamber", selection: $chamber) {
                ForEach(Chamber.allCases, id: \.self) { c in
                    Text(c.rawValue).tag(c)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            if filteredTrades.isEmpty {
                ContentUnavailableView("Loading Trades", systemImage: "person.fill.checkmark", description: Text("Fetching politician stock trades from the last 90 days"))
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredTrades.prefix(100)) { trade in
                            TradeRow(trade: trade)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct TradeRow: View {
    let trade: CongressTrade

    var body: some View {
        HStack(spacing: 12) {
            // Buy/Sell indicator
            Image(systemName: trade.isPurchase ? "arrow.up.circle.fill" : trade.isSale ? "arrow.down.circle.fill" : "circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(trade.isPurchase ? NETheme.severityLow : trade.isSale ? NETheme.severityCritical : NETheme.textTertiary)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if let ticker = trade.ticker, ticker != "--" {
                        Text(ticker)
                            .font(NETheme.mono(13))
                            .foregroundStyle(NETheme.accent)
                    }
                    Text(trade.memberName)
                        .font(NETheme.body(13))
                        .foregroundStyle(NETheme.textPrimary)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    Text(trade.chamber)
                        .font(NETheme.mono(9))
                        .foregroundStyle(NETheme.textTertiary)
                    if let amount = trade.amount {
                        Text(amount)
                            .font(NETheme.mono(9))
                            .foregroundStyle(NETheme.textSecondary)
                    }
                }
            }

            Spacer()

            if let date = trade.transactionDate {
                Text(date)
                    .font(NETheme.mono(10))
                    .foregroundStyle(NETheme.textTertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassCard(cornerRadius: 10)
    }
}

// MARK: - Contracts View
struct ContractsView: View {
    @Environment(DataOrchestrator.self) private var data

    var body: some View {
        if data.recentContracts.isEmpty {
            ContentUnavailableView("Loading Contracts", systemImage: "doc.text.fill", description: Text("Fetching recent government contracts from USASpending.gov"))
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(data.recentContracts) { contract in
                        ContractCard(contract: contract)
                    }
                }
                .padding()
            }
        }
    }
}

struct ContractCard: View {
    let contract: USASpendingResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let name = contract.recipientName {
                    Text(name)
                        .font(NETheme.subheading(14))
                        .foregroundStyle(NETheme.textPrimary)
                        .lineLimit(1)
                }
                Spacer()
                if let amount = contract.awardAmount {
                    Text(formatCurrency(amount))
                        .font(NETheme.mono(13))
                        .foregroundStyle(NETheme.accent)
                }
            }

            if let desc = contract.description {
                Text(desc)
                    .font(NETheme.body(12))
                    .foregroundStyle(NETheme.textSecondary)
                    .lineLimit(2)
            }

            HStack(spacing: 12) {
                if let agency = contract.awardingAgencyName {
                    Label(agency, systemImage: "building.columns")
                        .lineLimit(1)
                }
                Spacer()
                if let date = contract.startDate {
                    Label(date, systemImage: "calendar")
                }
            }
            .font(NETheme.caption(10))
            .foregroundStyle(NETheme.textTertiary)
        }
        .padding()
        .glassCard()
    }

    private func formatCurrency(_ amount: Double) -> String {
        if amount >= 1_000_000_000 { return String(format: "$%.2fB", amount / 1_000_000_000) }
        if amount >= 1_000_000 { return String(format: "$%.1fM", amount / 1_000_000) }
        if amount >= 1_000 { return String(format: "$%.0fK", amount / 1_000) }
        return String(format: "$%.0f", amount)
    }
}

// MARK: - Lobbying View
struct LobbyingView: View {
    @Environment(DataOrchestrator.self) private var data

    var body: some View {
        if data.lobbyingFilings.isEmpty {
            ContentUnavailableView("Loading Lobbying Data", systemImage: "building.columns.fill", description: Text("Fetching lobbying disclosures from the Senate LDA"))
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(data.lobbyingFilings, id: \.computedId) { filing in
                        LobbyingCard(filing: filing)
                    }
                }
                .padding()
            }
        }
    }
}

struct LobbyingCard: View {
    let filing: LobbyingFiling

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if let registrant = filing.registrantName {
                        Text(registrant)
                            .font(NETheme.subheading(14))
                            .foregroundStyle(NETheme.textPrimary)
                            .lineLimit(1)
                    }
                    if let client = filing.clientName {
                        Text("Client: \(client)")
                            .font(NETheme.body(12))
                            .foregroundStyle(NETheme.textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                if let income = filing.income, income > 0 {
                    Text(formatLobbyAmount(income))
                        .font(NETheme.mono(13))
                        .foregroundStyle(Color(hex: "#CE93D8"))
                }
            }

            if let activities = filing.lobbyingActivities, let first = activities.first {
                if let issueCode = first.generalIssueCode {
                    Text(issueCode)
                        .font(NETheme.mono(10))
                        .foregroundStyle(NETheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(NETheme.accent.opacity(0.1))
                        .clipShape(Capsule())
                }
                if let desc = first.description {
                    Text(desc)
                        .font(NETheme.body(11))
                        .foregroundStyle(NETheme.textTertiary)
                        .lineLimit(2)
                }
            }

            HStack {
                if let year = filing.filingYear, let period = filing.filingPeriod {
                    Text("\(year) \(period)")
                        .font(NETheme.mono(10))
                        .foregroundStyle(NETheme.textTertiary)
                }
            }
        }
        .padding()
        .glassCard()
    }

    private func formatLobbyAmount(_ amount: Double) -> String {
        if amount >= 1_000_000 { return String(format: "$%.1fM", amount / 1_000_000) }
        if amount >= 1_000 { return String(format: "$%.0fK", amount / 1_000) }
        return String(format: "$%.0f", amount)
    }
}
