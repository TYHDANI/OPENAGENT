import SwiftUI

struct EditHabitView: View {
    @Binding var habit: Habit
    @ObservedObject var habitRepository: HabitRepository
    @Environment(\.dismiss) private var dismiss

    @State private var habitName: String
    @State private var selectedColor: String
    @State private var selectedIcon: String
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date

    private let colors = ["blue", "green", "orange", "purple", "pink", "red", "yellow", "cyan", "indigo", "mint"]
    private let icons = [
        "star.fill", "heart.fill", "bolt.fill", "leaf.fill", "drop.fill",
        "book.fill", "pencil", "moon.fill", "sun.max.fill", "cloud.fill",
        "flame.fill", "figure.walk", "dumbbell.fill", "cup.and.saucer.fill", "brain.head.profile"
    ]

    init(habit: Binding<Habit>, habitRepository: HabitRepository) {
        self._habit = habit
        self.habitRepository = habitRepository
        _habitName = State(initialValue: habit.wrappedValue.name)
        _selectedColor = State(initialValue: habit.wrappedValue.color)
        _selectedIcon = State(initialValue: habit.wrappedValue.icon)
        _reminderEnabled = State(initialValue: habit.wrappedValue.reminderEnabled)
        _reminderTime = State(initialValue: habit.wrappedValue.reminderTime ?? Date())
    }

    var body: some View {
        Form {
            Section {
                TextField("Habit name", text: $habitName)
                    .textFieldStyle(.roundedBorder)
            } header: {
                Text("Name")
            }

            Section("Appearance") {
                // Color Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(color))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Icon Picker
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                    ForEach(icons, id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(selectedIcon == icon ? .white : Color(selectedColor))
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedIcon == icon ? Color(selectedColor) : Color(selectedColor).opacity(0.1))
                            )
                            .onTapGesture {
                                selectedIcon = icon
                            }
                    }
                }
            }

            Section {
                Toggle("Daily reminder", isOn: $reminderEnabled)

                if reminderEnabled {
                    DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }
            } header: {
                Text("Gentle Reminders")
            } footer: {
                Text("We'll send you encouraging notifications")
            }
        }
        .navigationTitle("Edit Habit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    saveChanges()
                }
                .fontWeight(.semibold)
                .disabled(habitName.isEmpty)
            }
        }
    }

    private func saveChanges() {
        habit.name = habitName
        habit.color = selectedColor
        habit.icon = selectedIcon
        habit.reminderEnabled = reminderEnabled
        habit.reminderTime = reminderEnabled ? reminderTime : nil

        habitRepository.updateHabit(habit)

        // Update notifications
        Task {
            if reminderEnabled {
                let granted = await NotificationService.shared.checkPermissionStatus() == .authorized
                if !granted {
                    _ = await NotificationService.shared.requestPermission()
                }
                try? await NotificationService.shared.scheduleReminder(for: habit)
            } else {
                await NotificationService.shared.cancelReminder(for: habit)
            }
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        EditHabitView(
            habit: .constant(Habit(name: "Meditation", color: "purple", icon: "brain.head.profile")),
            habitRepository: HabitRepository(persistenceController: .preview)
        )
    }
}