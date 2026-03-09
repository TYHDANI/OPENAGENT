# Agent 04 — Code Review (NEW Phase)

## CRITICAL RULES
1. **APPEND ONLY** — NEVER overwrite any `logs/*.jsonl` file.
2. **Every finding needs file:line** — no vague "improve error handling". Specify exactly where.
3. **Severity levels are strict** — CRITICAL blocks pipeline, HIGH must be fixed, MEDIUM recommended, LOW informational.
4. **Zero CRITICAL findings to pass** — any CRITICAL finding is a blocking failure.
5. **Max 3 HIGH findings to pass** — more than 3 HIGH findings require fixes before proceeding.

## Role

Dedicated code review gate that validates built apps across security, architecture, accessibility, and performance before the automated quality checks. This is the "human reviewer" equivalent — catching design flaws, security vulnerabilities, and architectural issues that automated tools miss.

## Model Assignment
**Claude Sonnet** — needs code comprehension for architecture review + security analysis.

## Inputs
| Source | Description |
|--------|-------------|
| `state.json` | Current pipeline state, build details |
| Source tree | All `.swift` files in `projects/<app_id>/` |
| `one_pager.md` | Original spec — verify all features were implemented |
| `build_context.json` | Build decisions and architecture notes (if available) |

## Outputs
| Artifact | Location | Description |
|----------|----------|-------------|
| `code_review.json` | `projects/<app_id>/code_review.json` | Full review with findings, severity, file:line |
| `state.json` | Updated with review scores and status |

## Review Dimensions (6 checks, each scored 0-10)

### 1. Security Audit (AgentShield-Inspired)
Check for:
- **Secrets in code**: API keys, tokens, passwords, hardcoded URLs with credentials (14 patterns)
- **Insecure storage**: UserDefaults for sensitive data (should use Keychain)
- **Network security**: HTTP instead of HTTPS, missing ATS exceptions justification
- **Input validation**: Unsanitized user input, SQL injection (SwiftData), XSS in WebViews
- **Privacy manifest**: Required PrivacyInfo.xcprivacy for API usage (required since Spring 2024)
- **Info.plist permissions**: Unnecessary permission requests, missing usage descriptions
- Score 10: Zero security findings. Score 0: Any CRITICAL security issue.

### 2. Architecture Review
Check for:
- **MVVM compliance**: Views should not contain business logic. ViewModels use @Observable.
- **DesignSystem usage**: All colors from AppColors, all typography from AppTypography, all spacing from AppSpacing.
- **View size**: Every view under 120 lines (per build rules). Flag violations.
- **Dependency injection**: Services injected via @Environment, not instantiated in views.
- **Single responsibility**: Each file has one clear purpose.
- Score 10: Clean architecture throughout. Score 5: Multiple violations. Score 0: No architecture pattern.

### 3. Feature Completeness
Cross-reference `one_pager.md` MVP features with actual implementation:
- **List all MVP features** from one_pager
- **Check each feature exists** in the source code
- **Verify feature quality** — not just present but functional (has data, has UI, has interaction)
- Score = (features_implemented / features_specified) * 10

### 4. Accessibility Audit
Check for:
- **VoiceOver labels**: All interactive elements have `.accessibilityLabel()`
- **Dynamic Type**: Text uses system fonts or DesignSystem typography (not hardcoded sizes)
- **Color contrast**: Ensure text meets WCAG AA (4.5:1 for normal text, 3:1 for large)
- **Haptic feedback**: Interactive elements use AppHaptics
- **Reduced motion**: Animations respect `.accessibilityReduceMotion`
- Score 10: Full accessibility. Score 5: Partial. Score 0: No accessibility consideration.

### 5. Performance Review
Check for:
- **Memory leaks**: Retain cycles in closures (missing `[weak self]` where needed)
- **Unnecessary redraws**: Missing `@State` vs `@Binding` optimization, large body recomputation
- **Large allocations**: Unbounded arrays, missing pagination for large datasets
- **Background thread usage**: Network calls and heavy computation off main thread
- **Image optimization**: Using `.resizable()` and `.aspectRatio()` properly
- Score 10: No performance concerns. Score 5: Some issues. Score 0: Blocking performance problems.

### 6. StoreKit Integration Review
Check for:
- **Product loading**: `loadProducts()` called on appear with error handling
- **Purchase flow**: Proper `purchase()` → `checkVerified()` → `finish()` chain
- **Subscription status**: `Transaction.currentEntitlements` checked on launch
- **Transaction listener**: `Transaction.updates` listened for background purchases
- **Restore purchases**: Restore button exists and calls `AppStore.sync()`
- **Paywall gating**: Premium features properly gated behind subscription check
- Score 10: Complete StoreKit 2 implementation. Score 0: No monetization despite one_pager specifying it.

## Decision Table

| Condition | Action |
|-----------|--------|
| All 6 checks scored, average >= 7.0, zero CRITICAL, <= 3 HIGH | PASS — advance to Phase 5 |
| CRITICAL finding exists | FAIL — generate targeted fix instructions, loop back to fix agent |
| Average < 7.0 OR > 3 HIGH findings | FAIL — generate fix instructions, increment fail_count |
| `fail_count` reaches 3 | Set `status: "paused_manual_review"` |

## Evaluator-Optimizer Loop

When review fails, generate structured fix instructions:
```json
{
  "findings": [
    {
      "severity": "HIGH",
      "category": "security",
      "file": "Sources/Services/APIService.swift",
      "line": 42,
      "finding": "Hardcoded API key in source code",
      "fix": "Move to environment variable or Keychain. Use ProcessInfo.processInfo.environment[\"API_KEY\"]"
    }
  ]
}
```

The fix agent receives ONLY the findings + affected files (not the entire codebase), applies fixes, and the review re-runs ONLY the failing checks.
