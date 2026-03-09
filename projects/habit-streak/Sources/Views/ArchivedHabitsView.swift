import SwiftUI

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
            loadArchivedHabits()
        }
    }

    private func loadArchivedHabits() {
        archivedHabits = habitRepository.fetchArchivedHabits()
    }

    private func restoreHabit(_ habit: Habit) {
        var restoredHabit = habit
        restoredHabit.isArchived = false
        habitRepository.updateHabit(restoredHabit)
        loadArchivedHabits()
    }
}

struct ArchivedHabitRow: View {
    let habit: Habit
    let onRestore: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: habit.icon)
                .font(.title2)
                .foregroundStyle(Color.habitColor(habit.color))
                .frame(width: 44, height: 44)
                .background(Color.habitColor(habit.color).opacity(0.1))
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