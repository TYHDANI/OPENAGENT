# Swift Coding Style Rules

## Naming Conventions

- **Types**: PascalCase — `HabitRepository`, `StoreManager`, `PaywallView`
- **Properties/methods**: camelCase — `isSubscribed`, `loadProducts()`, `calculateProgress(for:)`
- **Constants**: camelCase — `let maxRetries = 3`
- **Protocols**: PascalCase with descriptive adjective or noun — `Identifiable`, `HabitTracking`
- **Enums**: PascalCase type, camelCase cases — `enum Timeframe { case week, month, all }`
- **Boolean properties**: Use `is`, `has`, `should`, `can` prefixes — `isPurchasing`, `hasSubscription`
- **Closures**: Name the parameter, not just `$0` — prefer `habits.filter { habit in habit.isActive }` over `habits.filter { $0.isActive }` for closures with logic

## Formatting

- **Line length**: 120 characters max
- **Indentation**: 4 spaces (Xcode default)
- **Braces**: Opening brace on same line as declaration
- **Trailing commas**: Always in multi-line arrays/dictionaries
- **Blank lines**: One between methods, two between MARK sections
- **MARK comments**: Use `// MARK: - Section Name` to organize code sections
- **Import order**: `import SwiftUI` first, then Apple frameworks alphabetically, then local modules

## File Organization

```swift
// 1. Imports
import SwiftUI
import StoreKit

// 2. Main type declaration
struct PaywallView: View {
    // 3. Environment/State properties (grouped)
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var storeManager
    @State private var selectedProduct: Product?

    // 4. Body
    var body: some View { ... }

    // 5. Private computed properties
    private var isReady: Bool { ... }

    // 6. Private methods
    private func handlePurchase() { ... }
}

// 7. Subviews as separate structs
// MARK: - Product Card
struct ProductCard: View { ... }

// 8. Extensions
private extension Bundle { ... }

// 9. Preview
#Preview { ... }
```

## View Size Rules

- **Max 120 lines per view file** — extract subviews aggressively
- **Max 30 lines per body** — if longer, break into computed view properties or subviews
- **Max 5 @State properties per view** — if more, consider a ViewModel
- **One screen per file** — supporting subviews go in the same file below the main view

## Property Wrappers (Order)

1. `@Environment` properties
2. `@EnvironmentObject` / `@Bindable` properties
3. `@State` / `@Binding` properties
4. `@AppStorage` properties
5. Regular `let`/`var` properties

## Guard/Early Return

Always prefer early return over nested conditionals:
```swift
// Good
guard let product = selectedProduct else { return }
let success = await storeManager.purchase(product)

// Bad
if let product = selectedProduct {
    let success = await storeManager.purchase(product)
}
```

## Optionals

- **Never force-unwrap** in production code (`!`) — except for `URL(string: "known-static-url")!`
- Use `guard let` for early exit, `if let` for branching
- Prefer `??` default values over optional chaining when a sensible default exists
- Use `map`/`flatMap` on optionals when the transformation is simple

## Access Control

- Default to `private` for all properties and methods
- Use `internal` (implicit) only for types that other modules need
- Mark `@MainActor` on view models and any UI-touching code
- Never use `open` unless designing for subclassing (we don't)
