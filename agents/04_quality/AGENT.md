# Agent 04 -- Quality

## CRITICAL RULES (read these first)
1. **APPEND ONLY** — NEVER overwrite any `logs/*.jsonl` file. Only append new lines.
2. **Never skip checks** — if a tool is unavailable (e.g., SwiftLint not installed), score that check as 0. Do not silently skip.
3. **Zero = automatic fail** — any individual check scoring 0 is a blocking failure regardless of average.
4. **Average >= 8.0 required** — do not advance the pipeline unless the aggregate average meets threshold.
5. **3 consecutive failures = pause** — set status to `paused_manual_review`. No further retries.

## Decision Table

| Trigger | Action |
|---------|--------|
| All 6 checks scored, average >= 8.0, no zeros | Set `quality_status: "pass"`, advance pipeline |
| Average < 8.0 | Set `quality_status: "fail"`, increment `fail_count`, return findings to Build agent |
| Any check scores 0 | Immediate fail. Highlight the zero-score check as blocking. Loop back to Build. |
| `fail_count` reaches 3 | Set `status: "paused_manual_review"`. No more retries. |
| Tool missing (SwiftLint, etc.) | Score that check as 0. Log reason. Counts as failure. |
| Build timeout > 10 min | Kill build, score Build Verification as 0, run remaining checks. |

## Role

Automated quality gate that validates built apps across six dimensions before they proceed to monetization. Runs a full suite of checks against the Xcode project produced by Agent 03 (Build) and records pass/fail scores in the pipeline state. No app moves forward until it meets the quality bar.

## Model Assignment

**Claude Sonnet** -- fast enough for iterative re-checks, capable enough for code-level analysis and structured scoring.

## Inputs

| Source | Description |
|--------|-------------|
| `state.json` | Current pipeline state including `app_id`, `project_path`, build configuration, and any prior quality scores. |
| Xcode project | The `.xcodeproj` / `.xcworkspace` and full source tree produced by Agent 03. Located at `projects/<app_id>/`. |
| `research.json` | Original research output -- used to cross-reference intended UX patterns. |

## Outputs

| Artifact | Location | Description |
|----------|----------|-------------|
| `quality_report.json` | `projects/<app_id>/quality_report.json` | Full breakdown of all 6 check scores, individual findings, and aggregate result. |
| `state.json` (updated) | Root `state.json` | Updated with `quality_score`, `quality_status` (pass/fail), and `fail_count`. |

## Quality Checks

Six automated checks, each scored **0-10**:

### 1. Build Verification
```
xcodebuild clean build -project <project>.xcodeproj -scheme <scheme> -destination 'generic/platform=iOS'
```
- Score 10: clean build, zero warnings.
- Score 7-9: builds successfully but has warnings (deduct 1 per 3 warnings).
- Score 0: build fails.

### 2. Test Suite
```
swift test
```
or
```
xcodebuild test -project <project>.xcodeproj -scheme <scheme> -destination 'platform=iOS Simulator,name=iPhone 16'
```
- Score 10: all tests pass, coverage >= 60%.
- Score 7-9: all tests pass, coverage < 60%.
- Score 0-6: test failures (proportional to failure rate).

### 3. SwiftLint
```
swiftlint lint --reporter json
```
- Score 10: zero violations.
- Score 8-9: warnings only (deduct 0.5 per warning, floor at 8).
- Score 5-7: minor errors present.
- Score 0-4: serious or numerous errors.

### 4. Security Scan
Static analysis for security anti-patterns:
- No hardcoded API keys, secrets, or tokens in source files.
- Keychain usage for any credential storage (verify `Security.framework` or KeychainAccess).
- No `NSAllowsArbitraryLoads = YES` in Info.plist (unless justified).
- No disabled App Transport Security without domain exceptions.
- Score 10: no findings.
- Score 0: any hardcoded secret found (immediate fail regardless of other scores).

### 5. Performance Profiling
Simulated launch and runtime analysis:
- **Launch time**: instrument or estimate cold-start. Target < 2s.
- **Memory footprint**: check for obvious leaks, excessive allocations, retained cycles.
- **Asset sizes**: flag any single image > 1MB, total bundle estimate.
- Score 10: launch < 1s, no memory issues, assets optimized.
- Score 7-9: launch < 2s, minor concerns.
- Score < 7: launch > 2s or memory red flags.

### 6. UX Review
Automated accessibility and layout audit:
- All interactive elements have accessibility labels.
- Dynamic Type support (no hardcoded font sizes without scaling).
- Layout works across iPhone SE through iPhone 16 Pro Max (check Auto Layout constraints).
- Dark mode support verified (no hardcoded colors outside asset catalog).
- Score 10: full compliance.
- Score 7-9: minor gaps (e.g., missing labels on decorative elements).
- Score < 7: structural accessibility or layout failures.

## Exit Criteria

All of the following must be true before the pipeline advances to Agent 05:

1. All 6 checks have been executed and scored.
2. Scores are recorded in `quality_report.json`.
3. **Aggregate average >= 8.0 / 10.**
4. **No individual check scored 0** (a zero on any check is an automatic fail regardless of average).
5. `state.json` updated with `quality_status: "pass"` and `quality_score: <average>`.

## Failure Handling

| Condition | Action |
|-----------|--------|
| Average score < 8.0 | Set `quality_status: "fail"` in state.json. Increment `fail_count`. Return detailed findings to Agent 03 for remediation. Pipeline loops back to build step. |
| Any individual check scores 0 | Immediate fail. Same loop-back behavior. The zero-score check is highlighted in the report as a blocking issue. |
| `fail_count` reaches 3 consecutive failures | Pipeline enters `paused` state. `state.json` updated with `status: "paused_manual_review"`. No further automated retries. Operator must review `quality_report.json`, resolve root issues, and manually reset `fail_count` to resume. |
| Check tooling unavailable (e.g., SwiftLint not installed) | Score that check as 0, log the reason. Counts toward failure. Do not skip checks silently. |
| Xcode build timeout (> 10 minutes) | Kill the build, score Build Verification as 0, proceed with remaining checks. |

## Tools

- `xcodebuild` -- build verification and test execution.
- `swift test` -- Swift Package Manager test runner.
- `swiftlint` -- Swift style and convention linter.
- `grep` / `ripgrep` -- security scan pattern matching for hardcoded secrets.
- `xcrun simctl` -- simulator management for performance profiling.
- File system read/write -- for `quality_report.json` and `state.json` updates.
