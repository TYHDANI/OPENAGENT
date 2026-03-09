# Build Error Resolver

## Purpose

Automated pattern for resolving `xcodebuild` failures with minimal, targeted fixes. Based on the build-error-resolver pattern from everything-claude-code.

## Core Rules

1. **Minimal diffs only** — fix the specific error, don't refactor surrounding code
2. **One error at a time** — fix the most fundamental error first (often a missing import or type error that causes cascading failures)
3. **Stop if fix introduces new errors** — if your fix creates more errors than it solves, revert and try a different approach
4. **Max 5 attempts** — after 5 failed fix attempts, mark as `build_failure` and escalate to manual review
5. **Log every attempt** — append to `logs/decisions.jsonl` with the error, attempted fix, and result

## Error Resolution Playbook

### Tier 1: Quick Fixes (auto-resolve)

| Error Pattern | Fix |
|---------------|-----|
| `cannot find 'X' in scope` | Add missing import or fix typo in identifier |
| `type 'X' has no member 'Y'` | Check API, fix property/method name |
| `missing return in closure` | Add explicit return statement |
| `cannot convert value of type` | Add type cast or fix type mismatch |
| `use of unresolved identifier` | Check scope, add parameter or property |
| `extra argument in call` | Remove extra argument or fix function signature |
| `missing argument for parameter` | Add required argument |
| `cannot assign to property: 'X' is a 'let' constant` | Change `let` to `var` if appropriate |
| `result of call is unused` | Add `_ =` or `@discardableResult` |

### Tier 2: Structural Fixes (careful resolution)

| Error Pattern | Fix |
|---------------|-----|
| `protocol 'X' requires 'Y'` | Implement missing protocol requirement |
| `initializer 'init()' is inaccessible` | Add public init or use different initializer |
| `ambiguous use of 'X'` | Add explicit type annotation to disambiguate |
| `circular reference` | Restructure dependencies, use protocols |
| `@Observable requires iOS 17+` | Check deployment target or use ObservableObject |
| `#Predicate does not support` | Move logic out of predicate, filter in Swift |

### Tier 3: Architecture Issues (may need rollback)

| Error Pattern | Fix |
|---------------|-----|
| 50+ errors from one change | Revert the change, try different approach |
| Conflicting constraints | Review the full type hierarchy |
| Module not found | Check target membership and build settings |
| Linker errors | Check target dependencies and framework linking |

## Resolution Process

```
1. Run xcodebuild → capture output
2. Parse errors (ignore warnings for now)
3. Group errors by file
4. Identify the ROOT error (often the first, or a missing import that cascades)
5. Apply minimal fix for root error
6. Rebuild
7. If new error count < previous: continue fixing
8. If new error count >= previous: revert last fix, try alternative
9. Repeat until zero errors or max attempts reached
```

## Error Parsing

Extract structured error info from xcodebuild output:
```
/path/to/File.swift:42:15: error: cannot find 'AppColors' in scope
```

Parse into:
- **file**: `/path/to/File.swift`
- **line**: 42
- **column**: 15
- **severity**: error
- **message**: `cannot find 'AppColors' in scope`

## Cascading Error Detection

Many xcodebuild errors are cascading — one root cause produces 10+ errors. Signs of cascading:
- Multiple errors in the same file referencing the same missing type
- Errors that say "cannot find X" where X appears in an import or type definition
- All errors disappear when one fix is applied

**Strategy**: Fix the error in the earliest file/line first. Rebuild. Often 80% of errors disappear.

## Logging Template

```json
{
  "timestamp": "ISO8601",
  "project": "AppName",
  "agent": "03_build",
  "action": "build_error_fix",
  "attempt": 1,
  "error_count_before": 12,
  "root_error": "cannot find 'AppColors' in scope at Views/PaywallView.swift:15",
  "fix_applied": "Added 'import DesignSystem' to PaywallView.swift",
  "error_count_after": 0,
  "result": "success"
}
```

## Integration with Build Phase

The build error resolver is invoked automatically in **Phase C: Build Verification** of the Build Agent. When `xcodebuild` fails:

1. Build agent captures the error output
2. Resolver parses errors and identifies root cause
3. Resolver applies minimal fix
4. Build agent re-runs `xcodebuild`
5. Process repeats up to 5 times
6. If resolved: continue to Phase D (Review)
7. If unresolved: log failure, set `build_result: "failure"` in state.json
