# Swift Testing Rules

## Test Structure

### File Naming
- Test files mirror source files: `HabitViewModel.swift` → `HabitViewModelTests.swift`
- Test classes: `final class HabitViewModelTests: XCTestCase`
- Test methods: `func test_methodName_condition_expectedResult()`

### Naming Convention
```swift
func test_purchase_withValidProduct_returnsTrue() async throws { ... }
func test_loadHabits_whenEmpty_returnsEmptyArray() async throws { ... }
func test_calculateProgress_withCompletions_returnsCorrectPercentage() { ... }
```

## What to Test

### Must Test (Critical Path)
- **ViewModel business logic** — every public method
- **Data transformations** — model encoding/decoding, calculations
- **StoreKit flows** — purchase success, failure, restore (mock the store)
- **Navigation state** — correct routes for user actions
- **Error handling** — every error case produces the right user-facing message

### Should Test (Important)
- **Repository CRUD** — create, read, update, delete operations
- **Date calculations** — streaks, timeframes, scheduling
- **Input validation** — edge cases, empty strings, invalid data
- **Notification scheduling** — correct times, proper cancellation

### Skip Testing
- SwiftUI view body layout (use Previews instead)
- Apple framework internals (URLSession, StoreKit underlying behavior)
- Trivial getters/setters with no logic

## Test Patterns

### Arrange-Act-Assert
```swift
func test_addHabit_incrementsCount() async {
    // Arrange
    let repository = HabitRepository(modelContext: previewContext)
    let initialCount = repository.habits.count

    // Act
    repository.addHabit(name: "Exercise", icon: "figure.run", color: "blue")

    // Assert
    XCTAssertEqual(repository.habits.count, initialCount + 1)
}
```

### Mocking Pattern (Protocol-Based)
```swift
protocol StoreProviding {
    func products(for ids: [String]) async throws -> [Product]
    func purchase(_ product: Product) async throws -> Product.PurchaseResult
}

// Production
final class AppStoreProvider: StoreProviding { ... }

// Test
final class MockStoreProvider: StoreProviding {
    var productsToReturn: [Product] = []
    var purchaseResult: Product.PurchaseResult = .userCancelled

    func products(for ids: [String]) async throws -> [Product] {
        productsToReturn
    }
}
```

### Async Testing
```swift
func test_loadProducts_populatesArray() async {
    let viewModel = StoreManager(provider: MockStoreProvider())
    await viewModel.loadProducts()
    XCTAssertFalse(viewModel.products.isEmpty)
}
```

## Test Requirements per App

### Minimum Test Coverage
- At least **1 test per ViewModel public method**
- At least **1 test per must-have feature** (from one-pager)
- At least **1 test for error/edge case** per feature
- **StoreKit tests**: purchase success, purchase failure, restore

### Test File Structure
```
Tests/
  <AppName>Tests/
    ViewModels/
      HabitViewModelTests.swift
      StoreManagerTests.swift
    Models/
      HabitTests.swift
    Services/
      NotificationServiceTests.swift
    Helpers/
      MockStoreProvider.swift
      TestHelpers.swift
```

## Running Tests

```bash
# Run all tests
xcodebuild test \
  -target <AppName>Tests \
  SDKROOT=iphonesimulator \
  CODE_SIGNING_ALLOWED=NO \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | tee test_log.txt

# Check for failures
grep -c "TEST.*FAILED" test_log.txt
```

## Test Quality Checks

- [ ] No force-unwraps in tests (use `XCTUnwrap`)
- [ ] No `sleep()` in async tests (use `XCTestExpectation` or structured concurrency)
- [ ] Tests are independent — no shared mutable state between tests
- [ ] Tests run in under 10 seconds total
- [ ] Test names describe the scenario, not the implementation
