import Foundation

@Observable
final class DashboardViewModel {
    var accounts: [Account] = []
    var totalEstateValue: Double = 0
    var overallHealthStatus: HealthStatus = .unknown
    var isLoading = false
    var errorMessage: String?
    var lastSyncDate: Date?

    enum HealthStatus: String {
        case healthy
        case warning
        case critical
        case unknown

        var displayName: String {
            switch self {
            case .healthy: return "Healthy"
            case .warning: return "Warning"
            case .critical: return "Critical"
            case .unknown: return "Unknown"
            }
        }

        var color: String {
            switch self {
            case .healthy: return "green"
            case .warning: return "yellow"
            case .critical: return "red"
            case .unknown: return "gray"
            }
        }
    }

    private let persistence = PersistenceService.shared
    private let exchange = ExchangeService.shared

    func loadAccounts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            accounts = try await persistence.loadAccounts()
            computeTotals()
        } catch {
            errorMessage = "Failed to load accounts: \(error.localizedDescription)"
        }
    }

    func syncAllAccounts() async {
        isLoading = true
        defer { isLoading = false }

        var updatedAccounts: [Account] = []

        for var account in accounts {
            do {
                let result = try await exchange.fetchBalances(for: account)
                account.holdings = result.holdings
                account.totalValueUSD = result.totalValueUSD
                account.lastActivityDate = result.lastActivityDate ?? account.lastActivityDate
                account.lastSyncDate = Date()
                account.isConnected = true
                account.connectionError = nil
                account.dormancyStatus = computeDormancy(lastActivity: account.lastActivityDate)
            } catch {
                account.connectionError = error.localizedDescription
            }
            updatedAccounts.append(account)
        }

        accounts = updatedAccounts
        lastSyncDate = Date()
        computeTotals()

        do {
            try await persistence.saveAccounts(accounts)
        } catch {
            errorMessage = "Failed to save synced data"
        }
    }

    private func computeTotals() {
        totalEstateValue = accounts.reduce(0) { $0 + $1.totalValueUSD }

        let dormantCount = accounts.filter { $0.dormancyStatus == .dormant }.count
        let warningCount = accounts.filter { $0.dormancyStatus == .warning }.count
        let errorCount = accounts.filter { $0.connectionError != nil }.count

        if dormantCount > 0 || errorCount > accounts.count / 2 {
            overallHealthStatus = .critical
        } else if warningCount > 0 || errorCount > 0 {
            overallHealthStatus = .warning
        } else if accounts.isEmpty {
            overallHealthStatus = .unknown
        } else {
            overallHealthStatus = .healthy
        }
    }

    private func computeDormancy(lastActivity: Date?) -> DormancyStatus {
        guard let lastActivity else { return .unknown }
        let daysSince = Calendar.current.dateComponents([.day], from: lastActivity, to: Date()).day ?? 0
        if daysSince > 90 { return .dormant }
        if daysSince > 30 { return .warning }
        return .active
    }

    var allocationsByAsset: [(symbol: String, percentage: Double)] {
        guard totalEstateValue > 0 else { return [] }

        var assetTotals: [String: Double] = [:]
        for account in accounts {
            for holding in account.holdings {
                assetTotals[holding.symbol, default: 0] += holding.valueUSD
            }
        }

        return assetTotals
            .map { (symbol: $0.key, percentage: ($0.value / totalEstateValue) * 100) }
            .sorted { $0.percentage > $1.percentage }
    }
}
