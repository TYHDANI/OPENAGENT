# Agent 05 -- Monetization

## CRITICAL RULES (read these first)
1. **APPEND ONLY** — NEVER overwrite any `logs/*.jsonl` file. Only append new lines.
2. **Revenue flows to the user** — all StoreKit products use the user's Apple Developer account. OPENAGENT never redirects revenue.
3. **Build must still pass** — after integrating StoreKit, run `xcodebuild clean build`. If it fails, roll back and retry.
4. **No hardcoded prices in UI** — always read prices from `Product` objects at runtime. Hardcoded prices cause App Store rejection.
5. **Include auto-renewal disclosure** — Apple requires subscription terms in the paywall. Always include.

## Role

Integrates StoreKit 2 into the validated app, establishing the revenue model. Generates subscription product definitions, builds a paywall UI with a free-trial-to-premium conversion pattern, and configures everything so revenue flows directly to the user's Apple Developer account. This agent does not handle App Store Connect configuration -- it prepares the in-app code and local StoreKit configuration for testing.

## Model Assignment

**Claude Sonnet** -- handles Swift code generation and StoreKit configuration templating with good speed-to-quality ratio.

## Inputs

| Source | Description |
|--------|-------------|
| `state.json` | Pipeline state including `app_id`, `project_path`, `app_category`, and quality gate status. |
| `research.json` | Market research output from Agent 01 -- includes competitor pricing, target audience, and monetization recommendations. |
| `validation.json` | Validation output from Agent 02 -- includes viability score and suggested price tier. |
| Xcode project | The quality-verified project from Agent 04. Located at `projects/<app_id>/`. |

## Outputs

| Artifact | Location | Description |
|----------|----------|-------------|
| `Products.storekit` | `projects/<app_id>/Products.storekit` | StoreKit 2 configuration file for local testing. Defines all subscription products, pricing, and trial periods. |
| `PaywallView.swift` | `projects/<app_id>/Sources/Paywall/PaywallView.swift` | SwiftUI paywall screen with free trial CTA, feature comparison, and premium conversion flow. |
| `StoreManager.swift` | `projects/<app_id>/Sources/Paywall/StoreManager.swift` | StoreKit 2 transaction manager. Handles purchasing, restoration, entitlement checking, and receipt validation. |
| `SubscriptionStatus.swift` | `projects/<app_id>/Sources/Paywall/SubscriptionStatus.swift` | Observable object that exposes current subscription state to the app's view hierarchy. |
| `monetization.json` | `projects/<app_id>/monetization.json` | Summary of configured products, pricing, trial durations, and conversion strategy. |
| `state.json` (updated) | Root `state.json` | Updated with `monetization_status` and product identifiers. |

## Subscription Tier Strategy

Tiers are configured based on `app_category` from research:

| App Category | Free Trial | Monthly Price | Annual Price | Features Gated |
|-------------|-----------|---------------|--------------|----------------|
| Productivity | 7 days | $4.99 | $39.99 | Advanced features, sync, export |
| Health/Fitness | 7 days | $6.99 | $49.99 | Personalized plans, history, analytics |
| Education | 14 days | $3.99 | $29.99 | Full course access, offline mode |
| Finance | 7 days | $5.99 | $44.99 | Premium insights, unlimited tracking |
| Lifestyle | 7 days | $3.99 | $29.99 | Customization, ad removal, premium content |
| Utility | 3 days | $2.99 | $19.99 | Pro features, no limits |
| Default | 7 days | $4.99 | $34.99 | Premium tier access |

Annual pricing always reflects a ~30-35% discount over monthly to incentivize longer commitments.

## Revenue Model

- All revenue flows to the **user's Apple Developer account**.
- Apple retains **15%** under the App Store Small Business Program (for developers earning < $1M/year).
- The agent does not collect or redirect any revenue. OPENAGENT's business model is separate from the apps it builds.
- `Products.storekit` uses the user's bundle identifier as the product ID prefix (e.g., `com.user.appname.premium.monthly`).

## PaywallView Design Pattern

The generated `PaywallView.swift` follows a proven conversion pattern:

1. **Hero section** -- headline emphasizing the core value proposition (pulled from research).
2. **Feature comparison** -- two-column Free vs Premium grid.
3. **Social proof placeholder** -- configurable review/rating section.
4. **Trial CTA** -- prominent button: "Start Free Trial" with trial duration displayed.
5. **Plan toggle** -- monthly/annual switcher with savings badge on annual.
6. **Terms footer** -- links to Terms of Service and Privacy Policy. Auto-renewal disclosure text per Apple guidelines.
7. **Restore purchases** -- visible button for subscription restoration.

The paywall is presented:
- On first launch after onboarding (soft gate).
- When the user taps a premium-gated feature (hard gate).
- Configurable via `PaywallTrigger` enum.

## Exit Criteria

All of the following must be true before the pipeline advances to Agent 06:

1. `Products.storekit` is generated and parseable by Xcode.
2. `PaywallView.swift` compiles and renders correctly in the project.
3. `StoreManager.swift` handles `Product.products(for:)`, `purchase()`, `Transaction.currentEntitlements`, and `updates` listener.
4. At least two subscription products are defined (monthly + annual).
5. Free trial period is configured per the category table above.
6. `monetization.json` is written with all product details.
7. `state.json` updated with `monetization_status: "complete"`.
8. The project still builds cleanly after StoreKit integration (`xcodebuild clean build` passes).

## Failure Handling

| Condition | Action |
|-----------|--------|
| App category not found in tier table | Use "Default" tier. Log the fallback in `monetization.json`. |
| Build fails after StoreKit integration | Roll back monetization files, report the specific build error. Retry once with adjusted imports/targets. If second attempt fails, set `monetization_status: "failed"` and pause for review. |
| Bundle identifier missing from state | Cannot generate product IDs. Set `monetization_status: "blocked"`. Log error. Pipeline does not advance. |
| StoreKit 2 API unavailable (deployment target < iOS 15) | Raise deployment target to iOS 16.0 minimum. Log the change. If this breaks other project settings, pause for review. |
| Research data missing pricing recommendations | Fall back to Default tier. Proceed without competitor-informed pricing. |

## Tools

- `xcodebuild` -- verify project still builds after integration.
- File system read/write -- generate `.storekit`, `.swift` files, and update `state.json`.
- JSON parser -- read `research.json`, `validation.json`, write `monetization.json`.
- Template engine (string interpolation) -- populate StoreKit configuration and Swift source from category-based templates.
