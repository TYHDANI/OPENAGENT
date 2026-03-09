import SwiftUI

struct HabitsListView: View {
    @ObservedObject var habitRepository: HabitRepository
    @State private var selectedDate = Date()
    @State private var showingHabitDetail: Habit?

    private var calendar = Calendar.current

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Date Selector
                DateSelectorView(selectedDate: $selectedDate)
                    .padding(.horizontal)

                // Habits List
                if habitRepository.habits.isEmpty {
                    EmptyStateView()
                        .frame(maxHeight: .infinity)
                        .padding(.top, 50)
                } else {
                    VStack(spacing: 12) {
                        ForEach(habitRepository.habits) { habit in
                            HabitRowView(
                                habit: habit,
                                isCompleted: habitRepository.getCompletion(for: habit, on: selectedDate) != nil,
                                progress: habitRepository.calculateProgress(for: habit)
                            ) {
                                habitRepository.toggleCompletion(for: habit, on: selectedDate)
                            } onTap: {
                                showingHabitDetail = habit
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .sheet(item: $showingHabitDetail) { habit in
            NavigationStack {
                HabitDetailView(habit: habit, habitRepository: habitRepository)
            }
        }
    }
}

// MARK: - Date Selector

struct DateSelectorView: View {
    @Binding var selectedDate: Date
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 12) {
            // Month and Year
            Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
                .foregroundStyle(.primary)

            // Week view
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { date in
                    DayView(date: date, isSelected: calendar.isDate(date, inSameDayAs: selectedDate))
                        .onTapGesture {
                            selectedDate = date
                        }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var weekDays: [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else {
            return []
        }

        var days: [Date] = []
        var date = weekInterval.start

        for _ in 0..<7 {
            days.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }

        return days
    }
}

struct DayView: View {
    let date: Date
    let isSelected: Bool
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 6) {
            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(calendar.component(.day, from: date))")
                .font(.body)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color.clear)
                )
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Habit Row

struct HabitRowView: View {
    let habit: Habit
    let isCompleted: Bool
    let progress: HabitProgress
    let onToggle: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: habit.icon)
                    .font(.title2)
                    .foregroundStyle(Color.habitColor(habit.color))
                    .frame(width: 44, height: 44)
                    .background(Color.habitColor(habit.color).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Habit Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text("\(progress.totalCompletions) total completions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Completion Toggle
                Button {
                    onToggle()
                } label: {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isCompleted ? Color.green : Color(.systemGray3))
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No habits yet")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Tap the + button to create your first habit.\nRemember: progress over perfection!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        HabitsListView(habitRepository: HabitRepository(persistenceController: .preview))
            .navigationTitle("StreamFlow")
    }
}