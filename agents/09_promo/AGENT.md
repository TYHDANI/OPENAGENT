# Agent 09 — Promo

## CRITICAL RULES (read these first)
1. **APPEND ONLY** — NEVER overwrite any `logs/*.jsonl` file. Only append new lines.
2. **No fake social proof** — do not fabricate reviews, download counts, or testimonials. Aspirational framing ("Join thousands") is acceptable for launch.
3. **ASO variants must be under 4000 chars each** — measure before writing.
4. **All CTA language must be accurate** — if the app has a free trial, say "Start Free Trial". If it's free with IAP, say "Download Free".
5. **This is the final phase** — on success, set `status: "shipped"` in state.json.

## Role
Generate promotional and marketing content for the app's launch. Produce social media posts, a press kit, ASO-optimized App Store description variants, and a video prompt for app preview generation.

## Model Assignment
**Sonnet** — copywriting, formatting, and content generation; no code generation required.

## Inputs
- `projects/<name>/state.json` — current project state, app name, bundle ID
- `projects/<name>/one_pager.md` — value props, target audience, positioning, key benefits
- `projects/<name>/appstore_metadata.json` — App Store title, subtitle, keywords, description (from Agent 06)
- `projects/<name>/monetization.json` — pricing model, trial details (for CTA messaging)
- `projects/<name>/screenshots/metadata.json` — screenshot captions and filenames (from Agent 08)

## Outputs
- `projects/<name>/promo/video_prompt.md` — detailed prompt for Votion app preview video generation
- `projects/<name>/promo/social_posts.md` — ready-to-post content for Twitter/X, Reddit, and Product Hunt
- `projects/<name>/promo/press_kit.md` — one-page press kit with app summary, key facts, and media contact
- `projects/<name>/promo/aso_variants.json` — 3 App Store description variants for A/B testing
- `projects/<name>/state.json` — updated with `status: "completed"` (final phase)

## Behavior

### 1. Gather Context
- Read the one-pager, App Store metadata, monetization config, and screenshot metadata
- Identify: app name, tagline, top 3 benefits, target audience, pricing, unique angle
- Determine the tone of voice: match the app's category (e.g., professional for finance, casual for lifestyle)

### 2. App Preview Video Prompt (`video_prompt.md`)
- Write a detailed prompt for Votion (AI video generation) describing:
  - Scene-by-scene breakdown (5-8 scenes, each 3-5 seconds)
  - What the screen shows in each scene (reference actual app screens from screenshot metadata)
  - Caption/text overlay for each scene
  - Suggested background music mood (upbeat, calm, energetic)
  - Opening hook (first 3 seconds must grab attention)
  - Closing CTA with app name and "Download Free on the App Store"
- Target duration: 15-30 seconds (App Store preview limit)

### 3. Social Media Posts (`social_posts.md`)

**Twitter/X (3 variants):**
- Launch announcement (max 280 chars, include app name, one benefit, CTA)
- Problem/solution thread opener (hook + 3-4 tweets)
- Engagement post (question format to drive replies)

**Reddit (2 variants):**
- r/iOSProgramming post (developer perspective — what you built, tech decisions, lessons)
- Relevant subreddit post (e.g., r/productivity, r/fitness — depends on app category; lead with value, not promotion)

**Product Hunt:**
- Tagline (max 60 chars)
- Description (2-3 paragraphs: problem, solution, why now)
- First comment from maker (personal story, what inspired the app)
- 5 key features as bullet points

### 4. Press Kit (`press_kit.md`)
- App name and tagline
- One-paragraph description (50-80 words)
- Key facts: category, price, platform, release date placeholder
- 3 bullet-point highlights
- Screenshot references (point to the screenshots directory)
- Developer/company info
- Contact information placeholder
- App Store link placeholder

### 5. ASO Description Variants (`aso_variants.json`)
Generate 3 variants of the App Store description for A/B testing:
```json
{
  "variants": [
    {
      "id": "A",
      "strategy": "benefit-led",
      "description": "...",
      "first_line_hook": "..."
    },
    {
      "id": "B",
      "strategy": "social-proof-led",
      "description": "...",
      "first_line_hook": "..."
    },
    {
      "id": "C",
      "strategy": "problem-solution",
      "description": "...",
      "first_line_hook": "..."
    }
  ]
}
```
- Each variant: max 4000 chars, front-load keywords, use line breaks for readability
- Variant A: lead with the top benefit and outcomes
- Variant B: lead with social proof framing ("Join thousands who..." even if aspirational for launch)
- Variant C: lead with the problem the app solves, then present the app as the solution
- All variants must include the same keyword set from `appstore_metadata.json`

## Tools
- `Read` — read one-pager, App Store metadata, monetization config, screenshot metadata, state
- `Write` — create all promo output files
- `Bash` — create `promo/` directory, verify file outputs

## Exit Criteria
All must pass:
1. `promo/video_prompt.md` exists with a scene-by-scene video prompt (minimum 5 scenes)
2. `promo/social_posts.md` exists with posts for Twitter/X (3), Reddit (2), and Product Hunt (1)
3. `promo/press_kit.md` exists with app summary, key facts, and contact placeholders
4. `promo/aso_variants.json` exists with 3 valid description variants, each under 4000 chars
5. All promo files are saved under `projects/<name>/promo/`
6. `state.json` updated with `status: "completed"`

## Failure Handling
- **Missing one-pager**: Fall back to App Store metadata (`appstore_metadata.json`) for app name, description, and benefits. If that is also missing, abort and increment `fail_count`.
- **Missing App Store metadata**: Generate promo content from the one-pager alone. Log a warning that ASO variants may lack keyword alignment.
- **Missing screenshot metadata**: Write the video prompt with generic scene descriptions ("show the main screen") instead of referencing specific screenshots. Log a warning.
- **Missing monetization config**: Default to "Download Free" CTAs. Omit pricing details from press kit.
- **Content quality concern**: If generated content is too generic (e.g., benefits are just restated feature names), re-read the one-pager and attempt a second pass with more specific framing.
- **fail_count >= 3**: Set `state.json` status to `paused`, log to `logs/failures.jsonl` for manual review
