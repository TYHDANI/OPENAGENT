import Foundation
import CoreData
import Combine

/// Repository for managing habits and their completions
@MainActor
final class HabitRepository: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var habitCompletions: [HabitCompletion] = []

    private(set) var persistenceController: PersistenceController
    private var cancellables = Set<AnyCancellable>()

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        fetchHabits()
        setupCoreDataObservers()
    }

    // MARK: - Fetch

    func fetchHabits() {
        let request = CDHabit.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDHabit.createdAt, ascending: false)]
        request.predicate = NSPredicate(format: "isArchived == %@", NSNumber(value: false))

        do {
            let cdHabits = try persistenceController.viewContext.fetch(request)
            habits = cdHabits.map { Habit(from: $0) }
            fetchAllCompletions()
        } catch {
            print("Failed to fetch habits: \(error)")
        }
    }

    private func fetchAllCompletions() {
        let request = CDHabitCompletion.fetchRequest()

        do {
            let cdCompletions = try persistenceController.viewContext.fetch(request)
            habitCompletions = cdCompletions.map { HabitCompletion(from: $0) }
        } catch {
            print("Failed to fetch completions: \(error)")
        }
    }

    // MARK: - Create

    func createHabit(name: String, color: String = "blue", icon: String = "star.fill") -> Habit {
        let context = persistenceController.viewContext
        let cdHabit = CDHabit(context: context)
        cdHabit.id = UUID()
        cdHabit.name = name
        cdHabit.createdAt = Date()
        cdHabit.color = color
        cdHabit.icon = icon
        cdHabit.reminderEnabled = false
        cdHabit.isArchived = false

        persistenceController.save()
        fetchHabits()

        return Habit(from: cdHabit)
    }

    // MARK: - Update

    func updateHabit(_ habit: Habit) {
        let context = persistenceController.viewContext
        let request = CDHabit.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", habit.id as CVarArg)

        do {
            if let cdHabit = try context.fetch(request).first {
                cdHabit.name = habit.name
                cdHabit.color = habit.color
                cdHabit.icon = habit.icon
                cdHabit.reminderEnabled = habit.reminderEnabled
                cdHabit.reminderTime = habit.reminderTime
                cdHabit.isArchived = habit.isArchived

                persistenceController.save()
                fetchHabits()
            }
        } catch {
            print("Failed to update habit: \(error)")
        }
    }

    // MARK: - Archive

    func archiveHabit(_ habit: Habit) {
        var updatedHabit = habit
        updatedHabit.isArchived = true
        updateHabit(updatedHabit)
    }

    // MARK: - Completions

    func toggleCompletion(for habit: Habit, on date: Date) {
        // Check if already completed today
        if let existingCompletion = getCompletion(for: habit, on: date) {
            // Remove completion
            deleteCompletion(existingCompletion)
        } else {
            // Add completion
            let context = persistenceController.viewContext
            let request = CDHabit.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", habit.id as CVarArg)

            do {
                if let cdHabit = try context.fetch(request).first {
                    let cdCompletion = CDHabitCompletion(context: context)
                    cdCompletion.id = UUID()
                    cdCompletion.completedAt = date
                    cdCompletion.habit = cdHabit

                    persistenceController.save()
                    fetchAllCompletions()
                }
            } catch {
                print("Failed to toggle completion: \(error)")
            }
        }
    }

    func getCompletion(for habit: Habit, on date: Date) -> HabitCompletion? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return habitCompletions.first { completion in
            completion.habitId == habit.id &&
            completion.completedAt >= startOfDay &&
            completion.completedAt < endOfDay
        }
    }

    func getCompletions(for habit: Habit) -> [HabitCompletion] {
        habitCompletions.filter { $0.habitId == habit.id }
    }

    private func deleteCompletion(_ completion: HabitCompletion) {
        let context = persistenceController.viewContext
        let request = CDHabitCompletion.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", completion.id as CVarArg)

        do {
            if let cdCompletion = try context.fetch(request).first {
                context.delete(cdCompletion)
                persistenceController.save()
                fetchAllCompletions()
            }
        } catch {
            print("Failed to delete completion: \(error)")
        }
    }

    // MARK: - Progress Calculation

    func calculateProgress(for habit: Habit) -> HabitProgress {
        let completions = getCompletions(for: habit)
        let calendar = Calendar.current
        let now = Date()

        // Calculate completions this week
        let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now)!
        let completionsThisWeek = completions.filter { $0.completedAt >= weekAgo }.count

        // Calculate completions this month
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
        let completionsThisMonth = completions.filter { $0.completedAt >= monthAgo }.count

        // Calculate average per week
        let daysSinceCreated = calendar.dateComponents([.day], from: habit.createdAt, to: now).day ?? 1
        let weeksSinceCreated = max(Double(daysSinceCreated) / 7.0, 1.0)
        let averagePerWeek = Double(completions.count) / weeksSinceCreated

        return HabitProgress(
            habit: habit,
            totalCompletions: completions.count,
            lastCompletedDate: completions.map { $0.completedAt }.max(),
            completionsThisWeek: completionsThisWeek,
            completionsThisMonth: completionsThisMonth,
            averageCompletionsPerWeek: averagePerWeek
        )
    }

    // MARK: - Archived Habits

    func fetchArchivedHabits() -> [Habit] {
        let request = CDHabit.fetchRequest()
        request.predicate = NSPredicate(format: "isArchived == %@", NSNumber(value: true))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDHabit.name, ascending: true)]

        do {
            let cdHabits = try persistenceController.viewContext.fetch(request)
            return cdHabits.map { Habit(from: $0) }
        } catch {
            print("Failed to fetch archived habits: \(error)")
            return []
        }
    }

    // MARK: - Core Data Observers

    private func setupCoreDataObservers() {
        NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.fetchHabits()
                }
            }
            .store(in: &cancellables)
    }
}