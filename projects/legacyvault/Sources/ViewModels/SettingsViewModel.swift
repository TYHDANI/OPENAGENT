import Foundation

@Observable
final class SettingsViewModel {
    var notificationsEnabled = false
    var dormancyAlertsEnabled = true
    var securityAlertsEnabled = true
    var portfolioAlertsEnabled = false
    var portfolioAlertThreshold = 20.0

    var currentTier: SubscriptionTier = .free
    var accountCount = 0
    var beneficiaryCount = 0

    var errorMessage: String?

    private let persistence = PersistenceService.shared
    private let notifications = NotificationService.shared

    func loadSettings() async {
        do {
            let accounts = try await persistence.loadAccounts()
            let beneficiaries = try await persistence.loadBeneficiaries()
            accountCount = accounts.count
            beneficiaryCount = beneficiaries.count
        } catch {
            errorMessage = "Failed to load settings"
        }
    }

    func requestNotificationPermission() async {
        notificationsEnabled = await notifications.requestAuthorization()
        if notificationsEnabled {
            await notifications.registerCategories()
        }
    }
}
