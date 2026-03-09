# YieldSentinel — Code Review Notes

**Reviewer**: Build Agent (self-review, manual)
**Date**: 2026-03-02
**Status**: Code complete, awaiting macOS build verification

## Critical Issues Found & Fixed

### 1. Package.swift Configuration Conflict (FIXED)
- **Issue**: Had both a `.library` product and an `.executableTarget` pointing to the same target. SPM cannot have a library product backed by an executable target.
- **Fix**: Removed `.library` product, changed `.executableTarget` to `.target` for proper test importability.
- **Impact**: Would have caused build failure on first attempt.

### 2. Test Template Placeholder (FIXED - Previous Session)
- **Issue**: `@testable import {{APP_NAME}}` — template placeholder not replaced.
- **Fix**: Replaced with `@testable import YieldSentinel`.

### 3. Test Assertion Mismatch (FIXED - Previous Session)
- **Issue**: Test asserted 3 product IDs but `StoreManager.allProductIDs` has 4.
- **Fix**: Updated assertion to match actual count (4).

## Code Quality Assessment

### Architecture: GOOD
- Clean MVVM separation with @Observable ViewModels
- Services are properly decoupled (DeFiDataService, AlertService, PersistenceService, StoreManager)
- ScoringEngine is a pure static struct — highly testable

### SwiftUI Patterns: GOOD
- @Environment for shared state (StoreManager)
- @Bindable for mutable ViewModel access in views
- @State for view-local state
- NavigationStack with type-safe navigation destinations

### Concurrency: GOOD
- DeFiDataService is an actor (thread-safe)
- async/await used consistently
- Task.detached for background transaction listener with weak self

### Potential Improvements (Non-Critical, for Quality Agent)

1. **Double data loading**: Both `ContentView` and `DashboardView` create separate `DashboardViewModel` instances. The dashboard loads data independently from the one passed to PortfolioView. Consider sharing a single instance via environment.

2. **Offline behavior**: If DeFiLlama API is unreachable and no cache exists, user sees an error. Consider adding built-in sample data for first launch.

3. **Score history**: `historicalScores` array is always empty because the DeFiDataService doesn't populate it. Future: persist daily scores and build history over time.

4. **Scoring engine peer comparison**: `peerComparison` factor returns a hardcoded 60.0. Needs actual peer data to be meaningful.

5. **Alert configurations**: No UI for editing alert thresholds per-product. The `AlertConfiguration` model supports it but there's no settings screen for it.

6. **Dynamic Type**: Most text uses system fonts which support Dynamic Type. Charts may need accessibility adjustments for very large text sizes.

## Security Review

- [x] No hardcoded API keys or secrets
- [x] No force-unwrapped optionals in production paths
- [x] Network requests use HTTPS only
- [x] UserNotifications permission requested properly
- [x] StoreKit transactions verified before granting entitlements
- [x] Legal disclaimer present in Settings and Paywall
- [x] `#if os(iOS)` guard on UIApplication.shared access

## Test Coverage

22 test cases covering:
- StoreManager initial state and product IDs
- ScoringEngine weight validation, high/low quality protocols, range checks
- Risk level mapping
- Risk factor status mapping and display names
- Alert evaluation (critical, moderate, none, disabled)
- Subscription tier feature limits
- YieldProduct formatting (TVL, APY, score change)
- PersistenceService round-trip
- Portfolio position creation
- AlertService add/read/unread count
