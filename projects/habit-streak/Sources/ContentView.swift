import SwiftUI

struct ContentView: View {
    @Environment(StoreManager.self) private var storeManager
    @StateObject private var habitRepository = HabitRepository()
    @State private var showingAddHabit = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - Habits Tab
            NavigationStack {
                HabitsListView(habitRepository: habitRepository)
                    .navigationTitle("StreamFlow")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showingAddHabit = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.accent)
                            }
                        }
                    }
            }
            .tabItem {
                Label("Habits", systemImage: "checkmark.circle.fill")
            }
            .tag(0)

            // MARK: - Progress Tab
            NavigationStack {
                ProgressDashboardView(habitRepository: habitRepository)
            }
            .tabItem {
                Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(1)

            // MARK: - Settings Tab
            NavigationStack {
                SettingsView()
                    .environment(storeManager)
                    .environmentObject(habitRepository)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(2)
        }
        .sheet(isPresented: $showingAddHabit) {
            NavigationStack {
                AddHabitView(habitRepository: habitRepository)
            }
        }
        .task {
            NotificationService.shared.setupNotificationCategories()
        }
    }
}

#Preview {
    ContentView()
        .environment(StoreManager())
}