import UserNotifications
import Foundation

/// Manages gentle reminder notifications for habits
final class NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }

    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Schedule Notifications

    func scheduleReminder(for habit: Habit) async throws {
        guard habit.reminderEnabled, let reminderTime = habit.reminderTime else {
            return
        }

        // Remove existing notification for this habit
        await cancelReminder(for: habit)

        // Create notification content with gentle, encouraging message
        let content = UNMutableNotificationContent()
        content.title = habit.name
        content.body = getGentleReminderMessage()
        content.sound = .default
        content.categoryIdentifier = "HABIT_REMINDER"
        content.userInfo = ["habitId": habit.id.uuidString]

        // Extract hour and minute components from reminder time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)

        // Create daily trigger
        var dateComponents = DateComponents()
        dateComponents.hour = components.hour
        dateComponents.minute = components.minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // Create and add request
        let request = UNNotificationRequest(
            identifier: notificationId(for: habit),
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    func cancelReminder(for habit: Habit) async {
        center.removePendingNotificationRequests(withIdentifiers: [notificationId(for: habit)])
    }

    func cancelAllReminders() async {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Helper Methods

    private func notificationId(for habit: Habit) -> String {
        "habit_reminder_\(habit.id.uuidString)"
    }

    private func getGentleReminderMessage() -> String {
        let messages = [
            "Take a moment for yourself 🌱",
            "Your future self will thank you",
            "Small steps lead to big changes",
            "You've got this! 💪",
            "Progress over perfection",
            "Every completion counts",
            "Building great habits, one day at a time",
            "Remember: it's okay if you miss sometimes",
            "Your journey continues here",
            "A gentle nudge to keep going"
        ]
        return messages.randomElement()!
    }

    // MARK: - Notification Actions

    func setupNotificationCategories() {
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_HABIT",
            title: "Mark Complete",
            options: [.foreground]
        )

        let skipAction = UNNotificationAction(
            identifier: "SKIP_HABIT",
            title: "Skip Today",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: "HABIT_REMINDER",
            actions: [completeAction, skipAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        center.setNotificationCategories([category])
    }
}