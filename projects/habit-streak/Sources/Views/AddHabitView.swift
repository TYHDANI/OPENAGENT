import SwiftUI

struct AddHabitView: View {
    @ObservedObject var habitRepository: HabitRepository
    @Environment(\.dismiss) private var dismiss

    @State private var habitName = ""
    @State private var selectedColor = "blue"
    @State private var selectedIcon = "star.fill"
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()

    private let colors = ["blue", "green", "orange", "purple", "pink", "red", "yellow", "cyan", "indigo", "mint"]
    private let icons = [
        "star.fill", "heart.fill", "bolt.fill", "leaf.fill", "drop.fill",
        "book.fill", "pencil", "moon.fill", "sun.max.fill", "cloud.fill",
        "flame.fill", "figure.walk", "dumbbell.fill", "cup.and.saucer.fill", "brain.head.profile"
    ]

    var body: some View {
        Form {
            Section {
                TextField("Habit name", text: $habitName)
                    .textFieldStyle(.roundedBorder)
            } header: {
                Text("Name")
            } footer: {
                Text("Choose a name that inspires you")
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
        .navigationTitle("New Habit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Create") {
                    createHabit()
                }
                .fontWeight(.semibold)
                .disabled(habitName.isEmpty)
            }
        }
    }

    private func createHabit() {
        var habit = habitRepository.createHabit(
            name: habitName,
            color: selectedColor,
            icon: selectedIcon
        )

        if reminderEnabled {
            habit.reminderEnabled = true
            habit.reminderTime = reminderTime
            habitRepository.updateHabit(habit)

            Task {
                let granted = await NotificationService.shared.requestPermission()
                if granted {
                    try? await NotificationService.shared.scheduleReminder(for: habit)
                }
            }
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        AddHabitView(habitRepository: HabitRepository(persistenceController: .preview))
    }
}