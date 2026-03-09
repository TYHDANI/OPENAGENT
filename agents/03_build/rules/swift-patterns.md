# Swift Architecture & Pattern Rules

## MVVM with SwiftUI

### ViewModel Pattern (iOS 17+)
```swift
@Observable
@MainActor
final class HabitViewModel {
    private let repository: HabitRepository

    var habits: [Habit] = []
    var isLoading = false
    var errorMessage: String?

    init(repository: HabitRepository) {
        self.repository = repository
    }

    func loadHabits() async {
        isLoading = true
        defer { isLoading = false }
        do {
            habits = try await repository.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### View → ViewModel Connection
```swift
struct HabitsListView: View {
    @State private var viewModel: HabitViewModel

    init(repository: HabitRepository) {
        _viewModel = State(initialValue: HabitViewModel(repository: repository))
    }

    var body: some View {
        List(viewModel.habits) { habit in ... }
            .task { await viewModel.loadHabits() }
    }
}
```

## SwiftData Patterns

### Model Definition
```swift
@Model
final class Habit {
    var name: String
    var icon: String
    var color: String
    var createdAt: Date
    var isArchived: Bool

    @Relationship(deleteRule: .cascade)
    var completions: [HabitCompletion]

    init(name: String, icon: String, color: String) {
        self.name = name
        self.icon = icon
        self.color = color
        self.createdAt = .now
        self.isArchived = false
        self.completions = []
    }
}
```

### Repository Pattern (wraps ModelContext)
```swift
@Observable
@MainActor
final class HabitRepository {
    private let modelContext: ModelContext

    var habits: [Habit] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchHabits()
    }

    func fetchHabits() {
        // SwiftData #Predicate: NO relationship traversal
        // Fetch all, filter in Swift
        let descriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        habits = (try? modelContext.fetch(descriptor))?.filter { !$0.isArchived } ?? []
    }
}
```

### SwiftData Rule: No Relationship Traversal in #Predicate
```swift
// WRONG — will crash at runtime
let predicate = #Predicate<Habit> { $0.completions.count > 0 }

// CORRECT — fetch all, filter in Swift
let all = try modelContext.fetch(FetchDescriptor<Habit>())
let withCompletions = all.filter { !$0.completions.isEmpty }
```

## Navigation Pattern

### Coordinator/Router with NavigationStack
```swift
struct ContentView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HabitsListView()
                .navigationDestination(for: Habit.self) { habit in
                    HabitDetailView(habit: habit)
                }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .settings: SettingsView()
                    case .progress: ProgressDashboardView()
                    }
                }
        }
    }
}
```

## StoreKit 2 Pattern

### StoreManager as @Observable
```swift
@Observable
@MainActor
final class StoreManager {
    var products: [Product] = []
    var isSubscribed = false
    var isPurchasing = false
    var activeSubscription: Product?
    var errorMessage: String?

    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            errorMessage = "Failed to load products"
        }
    }

    func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updateSubscriptionStatus()
                return true
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
```

## Error Handling Pattern

### Result Type for Service Layer
```swift
enum AppError: LocalizedError {
    case networkUnavailable
    case dataCorrupted
    case purchaseFailed(String)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable: "No internet connection"
        case .dataCorrupted: "Data could not be read"
        case .purchaseFailed(let reason): "Purchase failed: \(reason)"
        }
    }
}
```

### Async/Await Error Handling
```swift
// In ViewModel
func performAction() async {
    do {
        let result = try await service.fetch()
        self.data = result
    } catch is CancellationError {
        // Task was cancelled, no action needed
    } catch {
        self.errorMessage = error.localizedDescription
    }
}
```

## Environment Injection Pattern

### Passing dependencies through Environment
```swift
// App entry point
@main
struct MyApp: App {
    @State private var storeManager = StoreManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(storeManager)
        }
        .modelContainer(for: [Habit.self, HabitCompletion.self])
    }
}

// Consuming in any view
struct SettingsView: View {
    @Environment(StoreManager.self) private var storeManager
    // ...
}
```

## Concurrency Rules

- All UI updates must happen on `@MainActor`
- Use `.task {}` modifier for async work tied to view lifecycle (auto-cancels)
- Use `Task {}` in button actions (not auto-cancelled — use for fire-and-forget)
- Never use `DispatchQueue.main.async` — use `@MainActor` instead
- Use `withTaskGroup` for parallel async operations
- Always handle `CancellationError` in long-running tasks
