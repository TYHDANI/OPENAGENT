import Foundation

@Observable
final class AlertsViewModel {

    // MARK: - State

    var selectedSeverity: AlertSeverity?

    // MARK: - Dependencies

    let alertService: AlertService

    init(alertService: AlertService) {
        self.alertService = alertService
    }

    // MARK: - Computed

    var filteredAlerts: [AlertItem] {
        guard let severity = selectedSeverity else {
            return alertService.alerts
        }
        return alertService.alerts.filter { $0.severity == severity }
    }

    var criticalCount: Int {
        alertService.alerts.filter { $0.severity == .critical && !$0.isRead }.count
    }

    var moderateCount: Int {
        alertService.alerts.filter { $0.severity == .moderate && !$0.isRead }.count
    }

    var infoCount: Int {
        alertService.alerts.filter { $0.severity == .info && !$0.isRead }.count
    }

    var hasUnread: Bool {
        alertService.unreadCount > 0
    }

    // MARK: - Actions

    func markAsRead(_ alertID: UUID) {
        alertService.markAsRead(alertID)
    }

    func markAllAsRead() {
        alertService.markAllAsRead()
    }

    func deleteAlert(_ alertID: UUID) {
        alertService.deleteAlert(alertID)
    }

    func clearAll() {
        alertService.clearAlerts()
    }

    func requestNotifications() {
        alertService.requestNotificationPermission()
    }
}
