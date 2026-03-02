import SwiftUI
import CoreData

struct ArchivedHabitsView: View {
    @ObservedObject var habitRepository: HabitRepository
    @State private var archivedHabits: [Habit] = []

    var body: some View {
        List {
            if archivedHabits.isEmpty {
                ContentUnavailableView(
                    "No Archived Habits",
                    systemImage: "archivebox",
                    description: Text("Habits you archive will appear here")
                )
                .listRowBackground(Color.clear)
                .frame(height: 300)
            } else {
                ForEach(archivedHabits) { habit in
                    ArchivedHabitRow(
                        habit: habit,
                        onRestore: {
                            restoreHabit(habit)
                        }
                    )
                }
            }
        }
        .navigationTitle("Archived Habits")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            fetchArchivedHabits()
        }
    }

    private func fetchArchivedHabits() {
        let request = CDHabit.fetchRequest()
        request.predicate = NSPredicate(format: "isArchived == %@", NSNumber(value: true))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDHabit.name, ascending: true)]

        do {
            let cdHabits = try habitRepository.persistenceController.viewContext.fetch(request)
            archivedHabits = cdHabits.map { Habit(from: $0) }
        } catch {
            print("Failed to fetch archived habits: \(error)")
        }
    }

    private func restoreHabit(_ habit: Habit) {
        var restoredHabit = habit
        restoredHabit.isArchived = false
        habitRepository.updateHabit(restoredHabit)
        fetchArchivedHabits()
    }
}

struct ArchivedHabitRow: View {
    let habit: Habit
    let onRestore: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: habit.icon)
                .font(.title2)
                .foregroundStyle(Color(habit.color))
                .frame(width: 44, height: 44)
                .background(Color(habit.color).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.body)
                    .fontWeight(.medium)

                Text("Archived \(habit.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Restore") {
                onRestore()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ArchivedHabitsView(habitRepository: HabitRepository(persistenceController: .preview))
    }
}