# Verification Loop Pattern

## Purpose

Continuous build-test-fix cycle that ensures code quality before advancing to the next phase. Based on the verification loop from everything-claude-code.

## Loop Structure

```
┌─────────────────────────────────────────────┐
│                                             │
│  Write Code → Build → Test → Review → Fix  │
│       ▲                              │      │
│       └──────────────────────────────┘      │
│                                             │
│  Exit when: ALL checks pass                 │
│  Abort when: 5 consecutive failures         │
└─────────────────────────────────────────────┘
```

## Verification Steps

### Step 1: Compile Check
```bash
xcodebuild -target <AppName> SDKROOT=iphonesimulator CODE_SIGNING_ALLOWED=NO build 2>&1
```
- **Pass**: Zero errors in output
- **Fail**: Parse errors → apply build_error_resolver.md → rebuild
- **Max retries**: 5

### Step 2: Test Check
```bash
xcodebuild test -target <AppName>Tests SDKROOT=iphonesimulator CODE_SIGNING_ALLOWED=NO \
  -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1
```
- **Pass**: All tests pass
- **Fail**: Fix failing test or fix the code the test covers → retest
- **Max retries**: 3
- **Non-blocking**: If tests can't be fixed, log and continue (Quality agent handles it)

### Step 3: Static Analysis
```bash
# Check for force unwraps (excluding URL literals)
grep -rn '!\.' Sources/ --include='*.swift' | grep -v 'URL(string:' | grep -v 'test' | head -20

# Check for hardcoded secrets
grep -rn 'api_key\|apiKey\|secret\|password\|token' Sources/ --include='*.swift' | grep -v '// ' | head -20

# Check view line counts
find Sources/Views -name '*.swift' -exec wc -l {} \; | awk '$1 > 120 {print "WARNING: " $2 " has " $1 " lines (max 120)"}'
```
- **Pass**: No force unwraps, no secrets, all views under 120 lines
- **Fail**: Fix the specific violation → recheck

### Step 4: DesignSystem Compliance
```bash
# Check for raw color usage
grep -rn 'Color\.\(blue\|red\|green\|white\|black\|gray\)' Sources/Views/ --include='*.swift' | head -20

# Check for raw font usage
grep -rn '\.system(size:' Sources/Views/ --include='*.swift' | head -20

# Check for hardcoded spacing
grep -rn '\.padding([0-9]' Sources/Views/ --include='*.swift' | head -20
```
- **Pass**: Zero raw SwiftUI values in Views
- **Fail**: Replace with DesignSystem tokens → recheck

### Step 5: Feature Completeness
Compare implemented features against one-pager must-have list:
- Read `projects/<name>/one_pager.md` MVP scope
- Check each feature has corresponding view/viewmodel/service
- **Pass**: All must-have features have implementations
- **Fail**: Implement missing feature → restart loop from Step 1

## Loop Exit Conditions

### Success (advance to Phase D: Review)
- Step 1: Build succeeds with zero errors
- Step 2: Tests pass (or logged as non-blocking failures)
- Step 3: No security/quality violations
- Step 4: Full DesignSystem compliance
- Step 5: All must-have features implemented

### Failure (mark as build_failure)
- 5 consecutive build failures that can't be resolved
- Architecture-level issue requiring one-pager revision
- Missing Apple framework/entitlement that blocks the entire app

### Pause (save and resume next cycle)
- Context window running out
- Cost limit approaching
- Network/simulator unavailable

## State Tracking

The verification loop updates `state.json` with loop progress:

```json
{
  "verification_loop": {
    "iteration": 3,
    "compile_pass": true,
    "test_pass": true,
    "static_analysis_pass": false,
    "design_system_pass": true,
    "feature_complete": true,
    "issues_remaining": ["force unwrap in NetworkService.swift:42"],
    "last_run": "ISO8601"
  }
}
```

## Integration

This verification loop is used in two places:
1. **Build Agent (Phase 3)**: After initial implementation, before Review Pass
2. **Quality Agent (Phase 4)**: As the primary quality gate before advancing to Phase 5
