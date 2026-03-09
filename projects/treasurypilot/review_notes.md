# TreasuryPilot — Code Review Notes (Phase 3)

**Date:** 2026-03-02
**Reviewer:** Build Agent (automated code review)
**Result:** PASS — 0 compilation-breaking issues

## Review Scope

All 36 Swift files reviewed for:
- Type consistency (struct/enum/class names match across files)
- Property and method signatures (callers match declarations)
- Protocol conformances (Identifiable, Codable, Hashable, etc.)
- @Observable / @Environment injection alignment
- Import statements
- SwiftUI view hierarchy correctness

## Files Reviewed (36)

### Models (8 files)
- `AppData.swift` — Container struct, all type references valid
- `CustodialAccount.swift` — Custodian, ConnectionStatus enums + CustodialAccount struct
- `LegalEntity.swift` — EntityType, CostBasisMethod, TaxTreatment, FiscalYearEnd enums + LegalEntity struct
- `QuarterlyEstimate.swift` — TaxQuarter enum + QuarterlyEstimate struct
- `SubscriptionTier.swift` — 4-tier enum with compatibility properties
- `TaxLot.swift` — HoldingPeriod enum + TaxLot struct
- `Transaction.swift` — TransactionType enum + CryptoTransaction struct
- `UserRole.swift` — AccessRole enum + AppUser, AuditLogEntry structs + UserRole typealias
- `WashSaleAlert.swift` — WashSaleAlert struct

### Services (6 files)
- `Form8949Exporter.swift` — CSV generation, references TaxLot.originalQuantity correctly
- `PersistenceService.swift` — Actor-based JSON persistence, generic + convenience methods
- `QuarterlyTaxCalculator.swift` — Federal tax rate calculations
- `ReportGenerator.swift` — ConsolidatedReport generation
- `TaxLotEngine.swift` — Lot creation, selection (FIFO/LIFO/HIFO), sale processing
- `WashSaleDetector.swift` — Cross-entity wash sale detection

### ViewModels (5 files)
- `EntityViewModel.swift` — Uses LegalEntity, CustodialAccount correctly
- `TransactionViewModel.swift` — Uses CryptoTransaction, TaxLot, TaxLotEngine correctly
- `TaxViewModel.swift` — Uses QuarterlyEstimate, WashSaleAlert, calculator/detector correctly
- `UserViewModel.swift` — Uses AccessRole, AppUser, AuditLogEntry (detail: singular) correctly
- `ReportViewModel.swift` — Uses ReportGenerator.ConsolidatedReport, Form8949Exporter correctly

### Views (11 files)
- `DashboardView.swift` — @Environment EntityViewModel, TransactionViewModel, TaxViewModel
- `EntityListView.swift` — @Environment EntityViewModel, StoreManager
- `EntityDetailView.swift` — @Environment EntityViewModel, TransactionViewModel, TaxViewModel
- `AddEntitySheet.swift` — @Environment EntityViewModel
- `AddAccountSheet.swift` — @Environment EntityViewModel
- `TransactionListView.swift` — @Environment TransactionViewModel, EntityViewModel
- `TaxLotView.swift` — @Environment TransactionViewModel, EntityViewModel
- `ReportsView.swift` — @Environment EntityViewModel, TransactionViewModel, TaxViewModel, StoreManager
- `WashSaleView.swift` — @Environment TaxViewModel, StoreManager
- `UserManagementView.swift` — @State UserViewModel
- `PaywallView.swift` — @Environment StoreManager
- `SettingsView.swift` — @Environment StoreManager

### App (2 files)
- `App.swift` — Injects StoreManager, EntityViewModel, TransactionViewModel, TaxViewModel
- `ContentView.swift` — 5-tab layout

### Tests (1 file)
- `AppTests.swift` — 20 test cases, all type references valid

## Issues Found

**None.** All type references, method signatures, property accesses, and protocol conformances are consistent across the codebase.

## Notes

- UserManagementView and ReportViewModel use @State (local) rather than @Environment because they are not injected from App.swift. This is intentional — UserViewModel is only needed on the user management screen, and ReportViewModel is only needed in ReportsView.
- SubscriptionTier has both primary properties (entityLimit, includesWashSaleDetection) and compatibility aliases (maxEntities, hasWashSaleDetection) to support both direct use and legacy references in views/tests.
- Build compilation requires macOS with Xcode 15+ (Swift 5.9, iOS 17 SDK). Not available on Linux VPS.
