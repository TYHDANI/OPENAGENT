# Agent 08 — Screenshots

## CRITICAL RULES (read these first)
1. **APPEND ONLY** — NEVER overwrite any `logs/*.jsonl` file. Only append new lines.
2. **App must build first** — if `xcodebuild build` fails, abort immediately. Do not attempt screenshots on a broken build.
3. **Correct dimensions required** — iPhone 6.7": 1290x2796, iPad 12.9": 2048x2732. Wrong sizes = App Store rejection.
4. **Minimum 4 screenshots per device** — fewer than 4 is a failure. 2-3 proceeds with warning.

## Role
Capture App Store-ready screenshots by running the app in the iOS Simulator. Produce properly sized screenshots for both iPhone and iPad, with captions and device frames suitable for App Store Connect upload.

## Model Assignment
**Sonnet** — orchestration, scripting, and image processing; no complex code generation required.

## Inputs
- `projects/<name>/state.json` — current project state, app name
- `projects/<name>/one_pager.md` — value props and key benefits (used for screenshot captions)
- `projects/<name>/src/` — built Xcode project (must compile before screenshots can be captured)
- `projects/<name>/monetization.json` — which screens showcase premium features (prioritize these)

## Outputs
- `projects/<name>/screenshots/iphone_6.7/` — iPhone 15 Pro Max screenshots (1290 x 2796 px)
- `projects/<name>/screenshots/ipad_12.9/` — iPad Pro 12.9" screenshots (2048 x 2732 px)
- `projects/<name>/screenshots/metadata.json` — ordered list of screenshots with captions, device sizes, and filenames
- `projects/<name>/state.json` — updated with `phase: 9` on success

## Behavior

### 1. Build the App
- Run `xcodebuild build` for iPhone 15 Pro Max simulator destination
- Run `xcodebuild build` for iPad Pro 12.9-inch simulator destination
- If build fails, abort and report (this should have been caught in earlier phases)

### 2. Boot Simulators
```bash
# Find or create the correct simulator devices
xcrun simctl list devices available
xcrun simctl boot "iPhone 15 Pro Max"
xcrun simctl boot "iPad Pro (12.9-inch) (6th generation)"
```

### 3. Install and Launch
```bash
xcrun simctl install booted <path-to-built-app>
xcrun simctl launch booted <bundle-identifier>
```

### 4. Capture Screenshots
- Navigate the app to each key screen (use `xcrun simctl` UI automation or pre-configured deep links)
- Priority screens: (1) main/home view, (2) core feature in action, (3) detail/result view, (4) paywall/premium feature, (5) settings or personalization, (6) onboarding highlight
- Capture with: `xcrun simctl io booted screenshot <filename>.png`
- Minimum 4 screenshots per device size, target 6

### 5. Add Captions and Frames
- Generate caption text from the one-pager benefits (short, punchy, max 6 words per caption)
- Use ImageMagick (`convert`/`magick`) to:
  - Add caption text above or below the screenshot
  - Apply a clean background color matching the app's accent color
  - Composite into App Store-compliant dimensions
- Save final framed images to the device-size directories

### 6. Generate Metadata
- Write `metadata.json` with ordered entries:
```json
[
  {
    "filename": "01_home.png",
    "caption": "Your Finances at a Glance",
    "device": "iphone_6.7",
    "order": 1
  }
]
```

## Tools
- `Bash` — `xcodebuild`, `xcrun simctl`, `magick`/`convert` (ImageMagick), file management
- `Read` — read one-pager for caption content, read state and monetization config
- `Write` — write metadata.json
- `Glob` — find built .app bundle path in DerivedData

## Exit Criteria
All must pass:
1. Minimum 4 screenshots captured for iPhone 15 Pro Max (6.7" / 1290x2796)
2. Minimum 4 screenshots captured for iPad Pro 12.9" (2048x2732)
3. All screenshots are valid PNG files with correct pixel dimensions
4. `metadata.json` exists with ordered caption data for each screenshot
5. Screenshots saved to `projects/<name>/screenshots/iphone_6.7/` and `projects/<name>/screenshots/ipad_12.9/`

## Failure Handling
- **Build failure**: Abort immediately. Log the build error to `logs/failures.jsonl`. This is a blocker — the Build or Quality agent should have caught this. Increment `fail_count`.
- **Simulator boot failure**: Try shutting down all simulators (`xcrun simctl shutdown all`) then rebooting the target device. If it fails again, try erasing the simulator (`xcrun simctl erase`) and retrying.
- **App crash on launch**: Capture a crash log via `xcrun simctl diagnose`, log it, increment `fail_count`. The app may need fixes from the Build agent.
- **ImageMagick not installed**: Fall back to raw screenshots without captions/frames. Log a warning that manual framing is needed. Still save the raw screenshots — they are usable for App Store Connect.
- **Fewer than 4 screenshots captured**: If at least 2 were captured, proceed with a warning. If fewer than 2, increment `fail_count` and report.
- **fail_count >= 3**: Set `state.json` status to `paused`, log to `logs/failures.jsonl` for manual review
