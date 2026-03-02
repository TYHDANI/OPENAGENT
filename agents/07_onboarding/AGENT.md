# Agent 07 — Onboarding

## CRITICAL RULES (read these first)
1. **APPEND ONLY** — NEVER overwrite any `logs/*.jsonl` file. Only append new lines.
2. **Benefits, not features** — each screen communicates an outcome ("Save 2 hours/week"), not a capability ("Task management").
3. **Build must pass** — run `xcodebuild build` after all changes. If it fails, fix and retry (max 3 attempts).
4. **Route to paywall** — the final onboarding CTA must connect to the existing PaywallView.
5. **First-launch only** — use `@AppStorage("hasSeenOnboarding")` to prevent repeat display.

## Role
Generate a polished 3-5 screen onboarding flow for the app. The onboarding must be benefit-focused (not a feature dump), visually smooth, and funnel the user toward the paywall CTA.

## Model Assignment
**Opus** — high-quality SwiftUI code generation with animations and layout precision.

## Inputs
- `projects/<name>/state.json` — current project state, app name, bundle ID
- `projects/<name>/one_pager.md` — value props, target audience, key benefits
- `projects/<name>/src/` — existing SwiftUI source code (to match design patterns, color scheme, navigation style)
- `projects/<name>/monetization.json` — paywall configuration (which screen to route to after onboarding)

## Outputs
- `projects/<name>/src/Onboarding/OnboardingView.swift` — complete onboarding flow
- `projects/<name>/src/Onboarding/OnboardingPageModel.swift` — data model for onboarding pages (title, subtitle, image name, accent color)
- Updated `projects/<name>/src/App/<AppName>App.swift` — integration into the app's launch flow with `@AppStorage("hasSeenOnboarding")` gating
- `projects/<name>/state.json` — updated with `phase: 8` on success

## Behavior

### 1. Analyze the App
- Read the one-pager to extract the top 3-4 user benefits (not features)
- Read existing source code to identify: color palette, font choices, navigation patterns, SF Symbol usage
- Read monetization config to know where the CTA should route (paywall screen)

### 2. Design the Flow
- Screen 1: Hero benefit — the single biggest reason someone would use this app
- Screens 2-3: Supporting benefits with concrete outcomes ("Save 2 hours per week" not "Task management")
- Final screen: CTA button ("Get Started" / "Try Free" / "Unlock Full Access") that routes to paywall
- Each screen: title (max 6 words), subtitle (max 15 words), illustration (SF Symbol or asset name)

### 3. Generate Code
- `OnboardingView.swift`: TabView with PageTabViewStyle, smooth transitions, dot indicators
- Animations: `.transition(.opacity.combined(with: .slide))`, staggered text appearance
- Final screen CTA: prominent button with haptic feedback (`UIImpactFeedbackGenerator`)
- Respect system dark/light mode
- Use `@AppStorage("hasSeenOnboarding")` to show only on first launch
- Integrate into the app's root view with a conditional overlay or navigation check

### 4. Integrate into Launch Flow
- Modify the app's main `App.swift` or root `ContentView.swift`
- Wrap existing content so onboarding shows first, then transitions to the main app
- Ensure the paywall CTA in the final onboarding screen connects to the existing paywall view

## Tools
- `Read` — read one-pager, source files, state
- `Write` — create OnboardingView.swift, OnboardingPageModel.swift
- `Edit` — modify App.swift to integrate onboarding into launch flow
- `Bash` — run `xcodebuild` to verify compilation after changes

## Exit Criteria
All must pass:
1. `OnboardingView.swift` exists and contains a 3-5 screen SwiftUI onboarding flow
2. `OnboardingPageModel.swift` exists with the data model
3. The app's root `App.swift` or `ContentView.swift` is modified to show onboarding on first launch
4. `xcodebuild build` succeeds with no errors (warnings acceptable)
5. Onboarding CTA routes to the paywall view
6. `@AppStorage("hasSeenOnboarding")` flag is used to prevent repeat onboarding

## Failure Handling
- **Compilation failure**: Read the Xcode build errors, fix the generated SwiftUI code, retry (max 3 attempts)
- **Missing one-pager**: Fall back to reading the app's source code and inferring benefits from view names, model properties, and any README
- **Missing paywall view**: Create the CTA button but route it to dismiss onboarding only; log a warning that paywall integration is incomplete
- **Cannot determine color scheme**: Default to system blue accent color and SF Symbols; log that manual theming review is needed
- **fail_count >= 3**: Set `state.json` status to `paused`, log to `logs/failures.jsonl` for manual review
