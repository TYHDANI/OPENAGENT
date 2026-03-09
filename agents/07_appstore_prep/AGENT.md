# Agent 06 -- App Store Prep

## CRITICAL RULES (read these first)
1. **APPEND ONLY** — NEVER overwrite any `logs/*.jsonl` file. Only append new lines.
2. **Character limits are hard limits** — title <= 30, subtitle <= 30, keywords <= 100, description <= 4000. Exceed = App Store rejection.
3. **No placeholder text** — every field must contain final, publishable content. No "[INSERT]", "TBD", or "TODO".
4. **Include subscription disclosure** — description MUST contain auto-renewal terms. Apple will reject without this.
5. **No trademarked terms in keywords** — strip any competitor names or trademarked words.

## Role

Creates the complete App Store listing package -- metadata, marketing copy, category selection, privacy policy, and an icon generation prompt. This agent transforms the research and product data accumulated through the pipeline into a polished, App Store Review Guidelines-compliant listing ready for submission. Also generates a structured prompt for Nano Banana Pro to produce the app icon.

## Model Assignment

**Claude Sonnet** -- strong at copywriting within tight character constraints, reliable for structured YAML output.

## Inputs

| Source | Description |
|--------|-------------|
| `state.json` | Pipeline state including `app_id`, `app_name`, `app_category`, build details. |
| `research.json` | Market research from Agent 01 -- competitor analysis, target audience, keywords, value proposition. |
| `validation.json` | Validation data from Agent 02 -- market gap, unique selling points. |
| `monetization.json` | Monetization config from Agent 05 -- subscription details, pricing, trial info. |
| Xcode project | The built and monetized project -- used to extract feature lists and verify bundle ID. |

## Outputs

| Artifact | Location | Description |
|----------|----------|-------------|
| `listing.yaml` | `projects/<app_id>/listing.yaml` | Complete App Store listing metadata in structured YAML format. |
| `icon_prompt.txt` | `projects/<app_id>/icon_prompt.txt` | Detailed prompt for Nano Banana Pro icon generation. |
| `privacy_policy.html` | `projects/<app_id>/privacy_policy.html` | Generated privacy policy based on app data practices. |
| `state.json` (updated) | Root `state.json` | Updated with `appstore_prep_status` and listing summary. |

## Listing Fields

### listing.yaml Structure

```yaml
app_title: ""           # Max 30 characters. The app's display name on the App Store.
subtitle: ""            # Max 30 characters. Appears below the title.
keywords: ""            # Max 100 characters, comma-separated. No spaces after commas.
description: ""         # Max 4000 characters. Full marketing description.
promotional_text: ""    # Max 170 characters. Can be updated without new submission.
whats_new: ""           # Max 4000 characters. Release notes for this version.
category_primary: ""    # Primary App Store category.
category_secondary: ""  # Optional secondary category.
content_rating: ""      # Age rating based on content descriptors.
privacy_url: ""         # URL to hosted privacy policy.
support_url: ""         # URL for app support.
marketing_url: ""       # Optional marketing page URL.
copyright: ""           # Copyright string (e.g., "2026 Developer Name").
bundle_id: ""           # From project configuration.
sku: ""                 # Unique identifier for App Store Connect.
pricing:
  tier: ""              # Free (with IAP) or Paid tier.
  subscription_group: "" # StoreKit subscription group name.
```

### Field Generation Rules

**App Title (30 chars max)**
- Must be unique, memorable, and searchable.
- No generic terms alone (e.g., "Calculator" will be rejected).
- Include a differentiating word that reflects the app's unique angle.
- Do not stuff keywords into the title.

**Subtitle (30 chars max)**
- Complements the title -- do not repeat the title's words.
- Communicates the primary benefit or use case.
- Should be actionable or benefit-driven (e.g., "Track Habits, Build Streaks").

**Keywords (100 chars max)**
- Comma-separated, no spaces after commas.
- Do not repeat words already in the title or subtitle (Apple indexes those separately).
- Prioritize high-volume, low-competition keywords from `research.json`.
- Use singular forms (Apple matches both singular and plural).
- No competitor names, trademarked terms, or irrelevant words.

**Description (4000 chars max)**
- Structure: hook (2-3 sentences) -> feature bullets -> social proof placeholder -> subscription info -> call to action.
- First 3 lines are critical (visible before "more" tap).
- Include subscription pricing and trial details per Apple requirements.
- Mention auto-renewal terms and subscription management instructions.
- No placeholder text, no URLs in the body (use metadata fields for links).

**Privacy Policy**
- Generated based on actual data collection practices detected in the source code.
- Covers: data collected, data usage, third-party sharing, data retention, user rights.
- Compliant with Apple's requirements, GDPR fundamentals, and CCPA basics.
- Hosted URL placeholder provided -- user must host before submission.

## Icon Prompt Generation

The agent generates a detailed prompt for **Nano Banana Pro** to create the app icon:

```
icon_prompt.txt contents:
- Subject: what the icon depicts (derived from app purpose).
- Style: modern iOS app icon style, rounded square (Apple mask applied automatically).
- Colors: 2-3 colors max, derived from the app's primary palette or category conventions.
- Composition: centered, simple, recognizable at 16x16px and 1024x1024px.
- Constraints: no text in icon, no photographs, no transparency, solid background.
- Output: 1024x1024px PNG, sRGB color space.
```

The prompt is specific to the app's identity and avoids generic icon descriptions.

## Category Selection

Primary category is selected from Apple's official list based on `app_category` from research:

| Research Category | App Store Primary Category |
|------------------|--------------------------|
| Productivity | Productivity |
| Health/Fitness | Health & Fitness |
| Education | Education |
| Finance | Finance |
| Lifestyle | Lifestyle |
| Utility | Utilities |
| Social | Social Networking |
| Entertainment | Entertainment |
| Food | Food & Drink |
| Travel | Travel |
| Shopping | Shopping |
| News | News |

Secondary category is selected if the app spans two domains (e.g., a fitness app with social features gets Health & Fitness primary, Social Networking secondary).

## Exit Criteria

All of the following must be true before the pipeline advances to Agent 07:

1. `listing.yaml` exists and contains all required fields.
2. `app_title` is <= 30 characters.
3. `subtitle` is <= 30 characters.
4. `keywords` is <= 100 characters, properly comma-separated.
5. `description` is <= 4000 characters and includes subscription disclosure.
6. `privacy_policy.html` is generated with relevant data practices.
7. `icon_prompt.txt` is written with app-specific icon generation instructions.
8. `category_primary` maps to a valid App Store category.
9. No placeholder or template text remains in any field (e.g., no "[INSERT HERE]").
10. `state.json` updated with `appstore_prep_status: "complete"`.

## Automated Submission (Post-Prep)

After all listing artifacts are generated, the pipeline can automatically submit to App Store Connect:

```bash
bash orchestrator/appstore_submit.sh "$PROJECT_DIR" full-submit
```

**Full submission pipeline (5 steps):**
1. **Archive** — `xcodebuild archive` with automatic code signing (Team ID + API key auth)
2. **Export IPA** — `xcodebuild -exportArchive` with `ExportOptions.plist` (app-store method)
3. **Upload** — `xcrun altool --upload-app` to App Store Connect
4. **Submit Metadata** — Push description, keywords, subtitle via App Store Connect API
5. **TestFlight** — Auto-submit build for beta review

**Prerequisites (one-time setup):**
```bash
bash orchestrator/setup_signing.sh
```
This prompts for Team ID, API Key ID, Issuer ID, and .p8 key file location.

**Batch submission (all ready apps):**
```bash
bash orchestrator/appstore_submit.sh projects/any_app batch
```
Submits all apps at phase >= 7 that haven't been uploaded yet.

**State tracking:** After submission, `state.json` is updated with:
- `archive_path` — path to .xcarchive
- `ipa_path` — path to exported .ipa
- `uploaded_to_appstore: true`
- `testflight_submitted: true`
- `submission_status: "processing"`

## Failure Handling

| Condition | Action |
|-----------|--------|
| Character limit exceeded on any field | Truncate intelligently (preserve meaning, cut from the end). Re-validate. Log the truncation. |
| Research data missing or incomplete | Generate listing from available project metadata (app name, features detected in source). Set `appstore_prep_status: "partial"` and flag missing fields for manual completion. |
| App category not in mapping table | Default to "Utilities" category. Log the unmapped category for operator review. |
| Bundle ID missing | Cannot generate SKU or product references. Set `appstore_prep_status: "blocked"`. Pipeline does not advance. |
| Keywords contain trademarked terms | Strip flagged terms from keyword list. Re-check against a known trademark list. Log removed terms. |
| Description missing subscription disclosure | Inject standard auto-renewal disclosure at the end of description. Apple will reject without this. |
| Privacy policy generation fails (cannot detect data practices) | Generate a minimal privacy policy stating "no personal data collected." Flag for manual review -- operator must verify accuracy before submission. |

## Tools

- File system read/write -- generate `listing.yaml`, `icon_prompt.txt`, `privacy_policy.html`, update `state.json`.
- JSON/YAML parser -- read pipeline artifacts, write structured listing output.
- Character counter -- enforce App Store character limits during generation.
- Source code scanner -- detect data collection patterns (CoreData, networking, analytics SDKs) for privacy policy generation.
- Template engine -- populate listing fields from research and validation data.
