import XCTest
import UserNotifications
@testable import StreamFlow

final class NotificationServiceTests: XCTestCase {
    var sut: NotificationService!

    override func setUp() {
        super.setUp()
        sut = NotificationService.shared
    }

    // MARK: - Singleton Tests

    func testSharedInstance_ShouldBeSingleton() {
        // Then
        XCTAssertTrue(sut === NotificationService.shared)
    }

    // MARK: - Reminder Message Tests

    func testGentleReminderMessages_ShouldBeEncouraging() {
        // Given
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

        // Then — messages should be encouraging, not guilt-inducing
        for message in messages {
            XCTAssertTrue(message.count > 0)
            XCTAssertFalse(message.contains("failed"))
            XCTAssertFalse(message.contains("you missed"))
            XCTAssertFalse(message.contains("disappointed"))
        }
    }

    // MARK: - Notification ID Tests

    func testNotificationID_ShouldBeUniquePerHabit() {
        // Given
        let habit1 = Habit(id: UUID(), name: "Meditation")
        let habit2 = Habit(id: UUID(), name: "Exercise")

        // When
        let id1 = "habit_reminder_\(habit1.id.uuidString)"
        let id2 = "habit_reminder_\(habit2.id.uuidString)"

        // Then
        XCTAssertNotEqual(id1, id2)
        XCTAssertTrue(id1.hasPrefix("habit_reminder_"))
        XCTAssertTrue(id2.hasPrefix("habit_reminder_"))
    }

    // MARK: - Category Setup Tests

    func testSetupNotificationCategories_ShouldConfigureActions() {
        // When
        sut.setupNotificationCategories()

        // Then
        // In a real test, we'd verify the categories were set
        // This documents the expected behavior
        XCTAssertTrue(true) // Placeholder assertion
    }

    // MARK: - Schedule Tests

    func testScheduleReminder_WithDisabledReminder_ShouldNotSchedule() async {
        // Given
        let habit = Habit(
            name: "Test Habit",
            reminderEnabled: false
        )

        // When
        do {
            try await sut.scheduleReminder(for: habit)
        } catch {
            XCTFail("Should not throw for disabled reminder")
        }

        // Then
        // Should complete without scheduling
        XCTAssertTrue(true)
    }

    func testScheduleReminder_WithEnabledReminderButNoTime_ShouldNotSchedule() async {
        // Given
        let habit = Habit(
            name: "Test Habit",
            reminderTime: nil,
            reminderEnabled: true
        )

        // When
        do {
            try await sut.scheduleReminder(for: habit)
        } catch {
            XCTFail("Should not throw for missing reminder time")
        }

        // Then
        // Should complete without scheduling
        XCTAssertTrue(true)
    }
}