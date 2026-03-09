import Foundation
import UserNotifications

actor NotificationService {
    static let shared = NotificationService()

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    // MARK: - Check-In Reminders

    func scheduleCheckInReminder(interval: CheckInInterval, nextDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "LegacyVault Check-In"
        content.body = "Confirm you're okay to keep your succession plan inactive."
        content.sound = .default
        content.categoryIdentifier = "CHECKIN"

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: nextDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "checkin-\(interval.rawValue)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Dormancy Warning

    func sendDormancyWarning(accountName: String, daysDormant: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Dormancy Alert"
        content.body = "\(accountName) has been inactive for \(daysDormant) days."
        content.sound = .default
        content.categoryIdentifier = "DORMANCY"

        let request = UNNotificationRequest(
            identifier: "dormancy-\(accountName)-\(daysDormant)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Security Alert

    func sendSecurityAlert(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Security Alert"
        content.body = message
        content.sound = .defaultCritical
        content.categoryIdentifier = "SECURITY"

        let request = UNNotificationRequest(
            identifier: "security-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Portfolio Alert

    func sendPortfolioAlert(changePercent: Double) {
        let direction = changePercent > 0 ? "up" : "down"
        let content = UNMutableNotificationContent()
        content.title = "Portfolio Alert"
        content.body = "Your portfolio is \(direction) \(String(format: "%.1f", abs(changePercent)))% in the last 24 hours."
        content.sound = .default
        content.categoryIdentifier = "PORTFOLIO"

        let request = UNNotificationRequest(
            identifier: "portfolio-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cancel

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )
    }

    // MARK: - Notification Categories

    func registerCategories() {
        let checkInAction = UNNotificationAction(
            identifier: "CONFIRM_CHECKIN",
            title: "I'm OK",
            options: .authenticationRequired
        )

        let checkInCategory = UNNotificationCategory(
            identifier: "CHECKIN",
            actions: [checkInAction],
            intentIdentifiers: []
        )

        let dormancyCategory = UNNotificationCategory(
            identifier: "DORMANCY",
            actions: [],
            intentIdentifiers: []
        )

        let securityCategory = UNNotificationCategory(
            identifier: "SECURITY",
            actions: [],
            intentIdentifiers: []
        )

        let portfolioCategory = UNNotificationCategory(
            identifier: "PORTFOLIO",
            actions: [],
            intentIdentifiers: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            checkInCategory, dormancyCategory, securityCategory, portfolioCategory
        ])
    }
}
