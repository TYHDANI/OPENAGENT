import Foundation

@Observable
final class ActivityViewModel {
    var transactions: [ActivityTransaction] = []
    var filteredTransactions: [ActivityTransaction] = []
    var isLoading = false
    var errorMessage: String?

    // Filters
    var selectedPlatform: ExchangePlatform?
    var selectedAsset: String?
    var selectedDateRange: DateRange = .all

    enum DateRange: String, CaseIterable, Identifiable {
        case today
        case week
        case month
        case year
        case all

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .today: return "Today"
            case .week: return "7 Days"
            case .month: return "30 Days"
            case .year: return "1 Year"
            case .all: return "All Time"
            }
        }
    }

    private let persistence = PersistenceService.shared

    func loadTransactions() async {
        isLoading = true
        defer { isLoading = false }

        do {
            transactions = try await persistence.loadTransactions()
            applyFilters()
        } catch {
            errorMessage = "Failed to load transactions: \(error.localizedDescription)"
        }
    }

    func applyFilters() {
        var result = transactions

        if let platform = selectedPlatform {
            result = result.filter { $0.platform == platform }
        }

        if let asset = selectedAsset {
            result = result.filter { $0.asset == asset }
        }

        let now = Date()
        switch selectedDateRange {
        case .today:
            result = result.filter { Calendar.current.isDateInToday($0.date) }
        case .week:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
            result = result.filter { $0.date >= weekAgo }
        case .month:
            let monthAgo = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
            result = result.filter { $0.date >= monthAgo }
        case .year:
            let yearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
            result = result.filter { $0.date >= yearAgo }
        case .all:
            break
        }

        filteredTransactions = result.sorted { $0.date > $1.date }
    }

    var anomalies: [ActivityTransaction] {
        transactions.filter { $0.anomalyLevel != .none }
            .sorted { $0.date > $1.date }
    }

    var uniqueAssets: [String] {
        Array(Set(transactions.map(\.asset))).sorted()
    }

    var uniquePlatforms: [ExchangePlatform] {
        Array(Set(transactions.map(\.platform))).sorted { $0.displayName < $1.displayName }
    }
}
