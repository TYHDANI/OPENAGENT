# LegacyVault — Build Review Notes

## Review Summary
- **Date**: 2026-03-02
- **Build Agent**: Opus
- **Review Method**: Self-review (different model unavailable on VPS; review_completed: false)

## Architecture Review

### Strengths
- Clean MVVM separation: Models → Services → ViewModels → Views
- `@Observable` used consistently for all ViewModels (modern iOS 17+ pattern)
- Actor-based services (PersistenceService, ExchangeService, NotificationService) for thread safety
- No force-unwraps in production code
- All API keys stored in Keychain, never in code or UserDefaults
- Proper use of `async/await` throughout, no legacy GCD

### Potential Issues
1. **ExchangeService API parsing** — JSON parsing uses `JSONSerialization` instead of `Codable` structs for API responses. This works but is less type-safe. Recommend defining response models in Phase 4.
2. **No offline cache TTL** — Exchange balances are fetched fresh each sync. Should add timestamp-based caching to reduce API calls.
3. **Background fetch not implemented** — The dead-man switch relies on app being opened for check-in. Needs `BGTaskScheduler` integration for true background monitoring.
4. **No error retry logic** — API failures don't have exponential backoff. Rate limiting could cascade.
5. **Price enrichment incomplete** — On-chain wallet balances don't include USD values (CoinGecko price fetch exists but isn't called automatically during sync).

## Security Review
- [PASS] No hardcoded API keys or secrets
- [PASS] Keychain storage uses `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- [PASS] No iCloud sync of credentials
- [PASS] Secure input fields for API keys (`SecureField`)
- [NOTE] Consider adding biometric authentication before showing API key management screens

## Accessibility Review
- [PASS] All interactive elements have accessibility labels
- [PASS] Dynamic Type respected (no hardcoded font sizes)
- [PASS] `accessibilityElement(children: .combine)` used on complex rows
- [NOTE] VoiceOver testing needed in simulator

## Features vs One-Pager Checklist
- [x] Dashboard with total estate value and health status
- [x] Account Connection for exchanges and wallets
- [x] Account Detail with holdings breakdown
- [x] Succession Plan Builder (multi-step flow)
- [x] Beneficiary Manager with CRUD
- [x] Activity Monitor with filtering
- [x] Dead-Man Switch with check-in
- [x] Notifications & Alerts (APNs categories registered)
- [x] Subscription Management (StoreKit 2, 4 tiers)

## Recommendations for Quality Phase
1. Add `BGTaskScheduler` for background dormancy monitoring
2. Implement CoinGecko price enrichment in sync pipeline
3. Add exponential backoff for API rate limiting
4. Consider adding CloudKit sync for multi-device (v1.1 feature)
5. Add biometric auth gate for sensitive screens
6. Run full accessibility audit in Xcode simulator
