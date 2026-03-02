import XCTest
@testable import StreamFlow

final class HabitRepositoryTests: XCTestCase {
    var sut: HabitRepository!
    var persistenceController: PersistenceController!

    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        sut = HabitRepository(persistenceController: persistenceController)
    }

    override func tearDown() {
        sut = nil
        persistenceController = nil
        super.tearDown()
    }

    // MARK: - Create Habit Tests

    func testCreateHabit_ShouldAddHabitToRepository() {
        // Given
        let habitName = "Test Meditation"
        let color = "purple"
        let icon = "brain.head.profile"

        // When
        let createdHabit = sut.createHabit(name: habitName, color: color, icon: icon)

        // Then
        XCTAssertEqual(sut.habits.count, 1)
        XCTAssertEqual(createdHabit.name, habitName)
        XCTAssertEqual(createdHabit.color, color)
        XCTAssertEqual(createdHabit.icon, icon)
        XCTAssertFalse(createdHabit.isArchived)
    }

    func testCreateMultipleHabits_ShouldAllowUnlimitedHabits() {
        // Given
        let habitCount = 20

        // When
        for i in 1...habitCount {
            _ = sut.createHabit(name: "Habit \(i)")
        }

        // Then
        XCTAssertEqual(sut.habits.count, habitCount)
    }

    // MARK: - Completion Tests

    func testToggleCompletion_ShouldAddCompletion() {
        // Given
        let habit = sut.createHabit(name: "Test Habit")
        let date = Date()

        // When
        sut.toggleCompletion(for: habit, on: date)

        // Then
        let completion = sut.getCompletion(for: habit, on: date)
        XCTAssertNotNil(completion)
        XCTAssertEqual(completion?.habitId, habit.id)
    }

    func testToggleCompletionTwice_ShouldRemoveCompletion() {
        // Given
        let habit = sut.createHabit(name: "Test Habit")
        let date = Date()

        // When
        sut.toggleCompletion(for: habit, on: date) // Add
        sut.toggleCompletion(for: habit, on: date) // Remove

        // Then
        let completion = sut.getCompletion(for: habit, on: date)
        XCTAssertNil(completion)
    }

    // MARK: - Progress Calculation Tests

    func testCalculateProgress_WithNoCompletions_ShouldReturnZero() {
        // Given
        let habit = sut.createHabit(name: "Test Habit")

        // When
        let progress = sut.calculateProgress(for: habit)

        // Then
        XCTAssertEqual(progress.totalCompletions, 0)
        XCTAssertNil(progress.lastCompletedDate)
        XCTAssertEqual(progress.completionsThisWeek, 0)
        XCTAssertEqual(progress.completionsThisMonth, 0)
    }

    func testCalculateProgress_WithMultipleCompletions_ShouldCalculateCumulativeProgress() {
        // Given
        let habit = sut.createHabit(name: "Test Habit")
        let calendar = Calendar.current

        // Add completions for different dates
        for i in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            sut.toggleCompletion(for: habit, on: date)
        }

        // When
        let progress = sut.calculateProgress(for: habit)

        // Then
        XCTAssertEqual(progress.totalCompletions, 10)
        XCTAssertNotNil(progress.lastCompletedDate)
        XCTAssertGreaterThan(progress.completionsThisWeek, 0)
        XCTAssertGreaterThan(progress.completionsThisMonth, 0)
    }

    // MARK: - Archive Tests

    func testArchiveHabit_ShouldHideFromActiveHabits() {
        // Given
        let habit = sut.createHabit(name: "Test Habit")
        XCTAssertEqual(sut.habits.count, 1)

        // When
        sut.archiveHabit(habit)

        // Then
        XCTAssertEqual(sut.habits.count, 0)
    }

    // MARK: - Update Tests

    func testUpdateHabit_ShouldPersistChanges() {
        // Given
        var habit = sut.createHabit(name: "Original Name")
        habit.name = "Updated Name"
        habit.color = "green"
        habit.reminderEnabled = true

        // When
        sut.updateHabit(habit)

        // Then
        let updatedHabit = sut.habits.first { $0.id == habit.id }
        XCTAssertEqual(updatedHabit?.name, "Updated Name")
        XCTAssertEqual(updatedHabit?.color, "green")
        XCTAssertTrue(updatedHabit?.reminderEnabled ?? false)
    }
}