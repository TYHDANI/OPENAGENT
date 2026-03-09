import SwiftUI

struct ProgressDashboardView: View {
    @ObservedObject var habitRepository: HabitRepository
    @Environment(StoreManager.self) private var storeManager
    @State private var selectedTimeframe: Timeframe = .week

    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case all = "All Time"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary Cards
                VStack(spacing: 16) {
                    OverallProgressCard(habitRepository: habitRepository)

                    HStack(spacing: 12) {
                        StatCard(
                            title: "Active Habits",
                            value: "\(habitRepository.habits.count)",
                            icon: "star.fill",
                            color: .blue
                        )

                        StatCard(
                            title: "Total Completions",
                            value: "\(totalCompletions)",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                    }
                }
                .padding(.horizontal)

                // Timeframe Picker
                Picker("Timeframe", selection: $selectedTimeframe) {
                    ForEach(Timeframe.allCases, id: \.self) { timeframe in
                        Text(timeframe.rawValue).tag(timeframe)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Habit Progress List
                VStack(alignment: .leading, spacing: 16) {
                    Text("Habit Performance")
                        .font(.headline)
                        .padding(.horizontal)

                    if habitRepository.habits.isEmpty {
                        EmptyProgressView()
                            .padding(.horizontal)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(habitRepository.habits) { habit in
                                HabitProgressRow(
                                    habit: habit,
                                    progress: habitRepository.calculateProgress(for: habit),
                                    timeframe: selectedTimeframe
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Pro Features
                if !storeManager.isSubscribed {
                    VStack(spacing: 12) {
                        ProFeatureCard(
                            title: "Export Progress Data",
                            description: "Download your data as CSV",
                            icon: "square.and.arrow.up"
                        )

                        ProFeatureCard(
                            title: "Advanced Analytics",
                            description: "Detailed insights and trends",
                            icon: "chart.line.uptrend.xyaxis"
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Progress")
    }

    private var totalCompletions: Int {
        habitRepository.habits.reduce(0) { total, habit in
            total + habitRepository.getCompletions(for: habit).count
        }
    }
}

// MARK: - Overall Progress Card

struct OverallProgressCard: View {
    @ObservedObject var habitRepository: HabitRepository

    private var message: String {
        let totalCompletions = habitRepository.habits.reduce(0) { total, habit in
            total + habitRepository.getCompletions(for: habit).count
        }

        switch totalCompletions {
        case 0:
            return "Start your journey today!"
        case 1...10:
            return "Great start! Keep going!"
        case 11...50:
            return "You're building momentum!"
        case 51...100:
            return "Amazing progress! 🌟"
        case 101...500:
            return "You're crushing it! 💪"
        default:
            return "Legendary consistency! 🏆"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Your Journey")
                .font(.headline)

            Text(message)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)

            Text("Remember: Every completion counts!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                colors: [Color.accentColor.opacity(0.1), Color.accentColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Habit Progress Row

struct HabitProgressRow: View {
    let habit: Habit
    let progress: HabitProgress
    let timeframe: ProgressDashboardView.Timeframe

    private var completionCount: Int {
        switch timeframe {
        case .week:
            return progress.completionsThisWeek
        case .month:
            return progress.completionsThisMonth
        case .all:
            return progress.totalCompletions
        }
    }

    private var targetCount: Int {
        switch timeframe {
        case .week:
            return 7
        case .month:
            return 30
        case .all:
            return max(progress.totalCompletions, 1)
        }
    }

    private var progressPercentage: Double {
        if timeframe == .all {
            return 1.0 // Always show full for all time
        }
        return min(Double(completionCount) / Double(targetCount), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: habit.icon)
                    .foregroundStyle(Color.habitColor(habit.color))

                Text(habit.name)
                    .font(.body)
                    .fontWeight(.medium)

                Spacer()

                Text("\(completionCount)")
                    .font(.headline)
                    .foregroundStyle(Color.habitColor(habit.color))
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.habitColor(habit.color))
                        .frame(width: geometry.size.width * progressPercentage, height: 8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progressPercentage)
                }
            }
            .frame(height: 8)

            if timeframe != .all {
                Text("\(completionCount) of \(targetCount) days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

// MARK: - Empty Progress View

struct EmptyProgressView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("No progress data yet")
                .font(.headline)

            Text("Create habits and start tracking to see your progress")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        ProgressDashboardView(habitRepository: HabitRepository(persistenceController: .preview))
            .environment(StoreManager())
    }
}