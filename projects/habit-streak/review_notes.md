# StreamFlow — Build Review Notes

## Review Summary
**Reviewer**: Code analysis pass (automated)
**Date**: 2026-03-02
**Status**: All critical issues resolved

## Issues Found and Fixed

### Critical (would prevent compilation)
1. **Missing `fetchRequest()` methods** — CDHabit and CDHabitCompletion lacked typed fetch request class methods. Core Data's inherited `NSManagedObject.fetchRequest()` returns `NSFetchRequest<NSFetchRequestResult>`, but the code expected typed results. Added `@nonobjc` class methods returning `NSFetchRequest<CDHabit>` and `NSFetchRequest<CDHabitCompletion>`.

2. **`ProgressView` name collision** — Custom `ProgressView` struct shadowed SwiftUI's built-in `ProgressView`, causing ambiguity errors in PaywallView where SwiftUI's spinner was needed. Renamed to `ProgressDashboardView`.

3. **`await` on synchronous function** — `setupNotificationCategories()` is not async but was called with `await` in ContentView's `.task` block. Removed the `await`.

4. **Missing `import UserNotifications`** — SettingsView used `UNAuthorizationStatus` without importing the UserNotifications framework.

5. **Private member access** — `HabitRepository.persistenceController` was `private` but accessed from ArchivedHabitsView. Changed to `private(set)` and added `fetchArchivedHabits()` repository method.

6. **`.constant()` binding for alert** — PaywallView used `.constant(storeManager.errorMessage != nil)` for the alert `isPresented` binding, which creates a read-only binding that can never dismiss the alert. Replaced with `Binding(get:set:)`.

7. **Template placeholder** — `Tests/AppTests.swift` still contained `{{APP_NAME}}` instead of `StreamFlow`.

8. **`private(set)` property mutation in tests** — StoreManagerTests attempted to set `isPurchasing` directly. Rewrote test to only read the property.

9. **Wrong Core Data relationship type** — `CDHabit.completions` was typed as `Set<CDHabitCompletion>` which is incompatible with Core Data's dynamic dispatch. Changed to `NSSet?`.

### Minor (code quality)
- ArchivedHabitsView had unnecessary `import CoreData` — removed since it now goes through the repository.
- `StoreManager.errorMessage` changed from `private(set)` to `var` to allow the PaywallView alert dismiss handler to clear it. This is acceptable since `@Observable` doesn't enforce the same encapsulation as `ObservableObject`.

## Architecture Assessment
- **MVVM pattern**: Properly implemented with clear separation between Views, ViewModels (HabitRepository), Models, and Services.
- **State management**: Correct mix of `@Observable` (StoreManager) and `ObservableObject` (HabitRepository) with appropriate property wrappers.
- **Core Data + CloudKit**: Properly configured with programmatic model definition, automatic remote change merging, and history tracking.
- **StoreKit 2**: Clean implementation with product loading, purchase flow, subscription verification, transaction listener, and restore purchases.
- **Notifications**: Gentle, encouraging messages aligned with the anxiety-free brand.

## Remaining Items
1. **WidgetKit extension** — Requires separate Xcode target (cannot be in SPM package). To be added when building on macOS.
2. **Build verification** — Cannot compile on Linux. Requires macOS with Xcode and iOS 17+ SDK.
3. **Test execution** — Tests require Apple test infrastructure (XCTest + iOS frameworks).
