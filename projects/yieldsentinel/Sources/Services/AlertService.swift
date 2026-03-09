import Foundation
#if canImport(UserNotifications)
import UserNotifications
#endif

/// Manages alert configurations, evaluates score changes, and dispatches notifications.
@Observable
final class AlertService {

    private(set) var alerts: [AlertItem] = []
    private(set) var configurations: [String: AlertConfiguration] = [:] // keyed by productID
    private let persistence: PersistenceService

    var unreadCount: Int {
        alerts.filter { !$0.isRead }.count
    }

    init(persistence: PersistenceService = .shared) {
        self.persistence = persistence
        loadAlerts()
        loadConfigurations()
    }

    // MARK: - Alert Evaluation

    func evaluateScoreChanges(products: [YieldProduct], previousScores: [String: Int]) {
        for product in products {
            guard let previousScore = previousScores[product.id] else { continue }

            let config = configurations[product.id] ?? AlertConfiguration(productID: product.id)

            guard let severity = ScoringEngine.evaluateAlerts(
                product: product,
                previousScore: previousScore,
                config: config
            ) else { continue }

            let scoreDrop = previousScore - product.sentinelScore
            let title: String
            let message: String

            switch severity {
            case .critical:
                title = "CRITICAL: \(product.name) score collapsed"
                message = "Sentinel Score dropped \(scoreDrop) points to \(product.sentinelScore). Immediate review recommended."
            case .moderate:
                title = "\(product.name) score declining"
                message = "Sentinel Score dropped \(scoreDrop) points to \(product.sentinelScore). Monitor closely."
            case .info:
                title = "\(product.name) score change"
                message = "Sentinel Score changed by \(scoreDrop) points to \(product.sentinelScore)."
            }

            let alert = AlertItem(
                productID: product.id,
                productName: product.name,
                severity: severity,
                title: title,
                message: message,
                scoreChange: -scoreDrop,
                previousScore: previousScore,
                currentScore: product.sentinelScore
            )

            addAlert(alert)
            scheduleNotification(alert)
        }
    }

    // MARK: - Alert Management

    func addAlert(_ alert: AlertItem) {
        alerts.insert(alert, at: 0)
        // Keep last 200 alerts
        if alerts.count > 200 {
            alerts = Array(alerts.prefix(200))
        }
        saveAlerts()
    }

    func markAsRead(_ alertID: UUID) {
        guard let index = alerts.firstIndex(where: { $0.id == alertID }) else { return }
        alerts[index].isRead = true
        saveAlerts()
    }

    func markAllAsRead() {
        for i in alerts.indices {
            alerts[i].isRead = true
        }
        saveAlerts()
    }

    func clearAlerts() {
        alerts.removeAll()
        saveAlerts()
    }

    func deleteAlert(_ alertID: UUID) {
        alerts.removeAll { $0.id == alertID }
        saveAlerts()
    }

    // MARK: - Configuration Management

    func setConfiguration(for productID: String, config: AlertConfiguration) {
        configurations[productID] = config
        saveConfigurations()
    }

    func getConfiguration(for productID: String) -> AlertConfiguration {
        configurations[productID] ?? AlertConfiguration(productID: productID)
    }

    func removeConfiguration(for productID: String) {
        configurations.removeValue(forKey: productID)
        saveConfigurations()
    }

    // MARK: - Notifications

    func requestNotificationPermission() {
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        #endif
    }

    private func scheduleNotification(_ alert: AlertItem) {
        #if canImport(UserNotifications)
        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.body = alert.message
        content.sound = alert.severity == .critical ? .defaultCritical : .default

        let request = UNNotificationRequest(
            identifier: alert.id.uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
        #endif
    }

    // MARK: - Persistence

    private func loadAlerts() {
        alerts = persistence.load(key: "alerts") ?? []
    }

    private func saveAlerts() {
        persistence.save(alerts, key: "alerts")
    }

    private func loadConfigurations() {
        configurations = persistence.load(key: "alertConfigurations") ?? [:]
    }

    private func saveConfigurations() {
        persistence.save(configurations, key: "alertConfigurations")
    }
}
