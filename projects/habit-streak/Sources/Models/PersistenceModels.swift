import Foundation
import CoreData

// MARK: - Habit Entity

/// Represents a habit that users want to track
@objc(CDHabit)
public class CDHabit: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var createdAt: Date
    @NSManaged public var reminderTime: Date?
    @NSManaged public var reminderEnabled: Bool
    @NSManaged public var color: String
    @NSManaged public var icon: String
    @NSManaged public var isArchived: Bool
    @NSManaged public var completions: NSSet?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDHabit> {
        return NSFetchRequest<CDHabit>(entityName: "CDHabit")
    }
}

// MARK: - HabitCompletion Entity

/// Represents a single completion of a habit on a specific date
@objc(CDHabitCompletion)
public class CDHabitCompletion: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var completedAt: Date
    @NSManaged public var note: String?
    @NSManaged public var habit: CDHabit

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDHabitCompletion> {
        return NSFetchRequest<CDHabitCompletion>(entityName: "CDHabitCompletion")
    }
}

// MARK: - Swift Models

/// Swift-native model for Habit
struct Habit: Identifiable, Equatable {
    let id: UUID
    var name: String
    var createdAt: Date
    var reminderTime: Date?
    var reminderEnabled: Bool
    var color: String
    var icon: String
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        reminderTime: Date? = nil,
        reminderEnabled: Bool = false,
        color: String = "blue",
        icon: String = "star.fill",
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.reminderTime = reminderTime
        self.reminderEnabled = reminderEnabled
        self.color = color
        self.icon = icon
        self.isArchived = isArchived
    }

    // Convert from Core Data entity
    init(from cdHabit: CDHabit) {
        self.id = cdHabit.id
        self.name = cdHabit.name
        self.createdAt = cdHabit.createdAt
        self.reminderTime = cdHabit.reminderTime
        self.reminderEnabled = cdHabit.reminderEnabled
        self.color = cdHabit.color
        self.icon = cdHabit.icon
        self.isArchived = cdHabit.isArchived
    }
}

/// Swift-native model for HabitCompletion
struct HabitCompletion: Identifiable, Equatable {
    let id: UUID
    var completedAt: Date
    var note: String?
    var habitId: UUID

    init(
        id: UUID = UUID(),
        completedAt: Date = Date(),
        note: String? = nil,
        habitId: UUID
    ) {
        self.id = id
        self.completedAt = completedAt
        self.note = note
        self.habitId = habitId
    }

    // Convert from Core Data entity
    init(from cdCompletion: CDHabitCompletion) {
        self.id = cdCompletion.id
        self.completedAt = cdCompletion.completedAt
        self.note = cdCompletion.note
        self.habitId = cdCompletion.habit.id
    }
}

// MARK: - Progress Statistics

/// Represents cumulative progress for a habit (not streak-based)
struct HabitProgress {
    let habit: Habit
    let totalCompletions: Int
    let lastCompletedDate: Date?
    let completionsThisWeek: Int
    let completionsThisMonth: Int
    let averageCompletionsPerWeek: Double
}