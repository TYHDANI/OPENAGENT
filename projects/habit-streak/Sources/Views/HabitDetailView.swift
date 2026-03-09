import SwiftUI

struct HabitDetailView: View {
    @State var habit: Habit
    @ObservedObject var habitRepository: HabitRepository
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var storeManager

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    private var progress: HabitProgress {
        habitRepository.calculateProgress(for: habit)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: habit.icon)
                        .font(.system(size: 60))
                        .foregroundStyle(Color.habitColor(habit.color))

                    Text(habit.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Created \(habit.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()

                // Progress Cards
                VStack(spacing: 16) {
                    // Total Completions (Main Focus)
                    ProgressCard(
                        title: "Total Completions",
                        value: "\(progress.totalCompletions)",
                        subtitle: "Every completion counts!",
                        color: Color.habitColor(habit.color),
                        isPrimary: true
                    )

                    HStack(spacing: 12) {
                        ProgressCard(
                            title: "This Week",
                            value: "\(progress.completionsThisWeek)",
                            subtitle: nil,
                            color: .blue
                        )

                        ProgressCard(
                            title: "This Month",
                            value: "\(progress.completionsThisMonth)",
                            subtitle: nil,
                            color: .green
                        )
                    }

                    ProgressCard(
                        title: "Average per Week",
                        value: String(format: "%.1f", progress.averageCompletionsPerWeek),
                        subtitle: "Since you started",
                        color: .purple
                    )
                }
                .padding(.horizontal)

                // Completion History (Pro Feature)
                if storeManager.isSubscribed {
                    CompletionHistoryView(habit: habit, habitRepository: habitRepository)
                        .padding(.horizontal)
                } else {
                    ProFeatureCard(
                        title: "Completion History",
                        description: "See detailed analytics and patterns",
                        icon: "chart.bar.fill"
                    )
                    .padding(.horizontal)
                }

                // Actions
                VStack(spacing: 12) {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Habit", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Habit", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.red)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationTitle("Habit Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                EditHabitView(habit: $habit, habitRepository: habitRepository)
            }
        }
        .alert("Delete Habit", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                habitRepository.archiveHabit(habit)
                dismiss()
            }
        } message: {
            Text("This will archive the habit and hide it from your list. Your progress data will be preserved.")
        }
    }
}

// MARK: - Progress Card

struct ProgressCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let color: Color
    var isPrimary: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Text(value)
                .font(isPrimary ? .system(size: 48, weight: .bold, design: .rounded) : .title2)
                .fontWeight(.bold)
                .foregroundStyle(color)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Pro Feature Card

struct ProFeatureCard: View {
    let title: String
    let description: String
    let icon: String
    @Environment(StoreManager.self) private var storeManager

    var body: some View {
        NavigationLink {
            PaywallView()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.accent)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.body)
                            .fontWeight(.medium)

                        Text("PRO")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Completion History (Pro)

struct CompletionHistoryView: View {
    let habit: Habit
    @ObservedObject var habitRepository: HabitRepository

    private var completions: [HabitCompletion] {
        habitRepository.getCompletions(for: habit)
            .sorted { $0.completedAt > $1.completedAt }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Completions")
                .font(.headline)

            if completions.isEmpty {
                Text("No completions yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical)
            } else {
                VStack(spacing: 8) {
                    ForEach(completions.prefix(10)) { completion in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)

                            Text(completion.completedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        HabitDetailView(
            habit: Habit(name: "Meditation", color: "purple", icon: "brain.head.profile"),
            habitRepository: HabitRepository(persistenceController: .preview)
        )
        .environment(StoreManager())
    }
}