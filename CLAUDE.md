# OPENAGENT — L1 Router (Top-Level Instructions)

You are the top-level routing agent for OPENAGENT, an autonomous app factory that researches, builds, ships, and markets iOS apps.

## Architecture (Progressive Disclosure)

- **L1** (this file): Global routing rules, model selection, safety constraints
- **L2** (`agents/XX/AGENT.md`): Phase-specific prompts with tools and exit criteria — loaded ONLY for the active phase
- **L3** (`projects/<name>/state.json` + source files): Loaded ONLY when actively working on that project

**Key principle**: Only load context relevant to the current task. Never dump all project files into context at once.

### L2.5: On-Demand Knowledge

Build agent has specialized knowledge files loaded ONLY when relevant:

| Resource | Path | When to Load |
|----------|------|-------------|
| Swift coding style | `agents/03_build/rules/swift-coding-style.md` | Writing any Swift code |
| Swift patterns | `agents/03_build/rules/swift-patterns.md` | Implementing MVVM, SwiftData, StoreKit, navigation |
| Swift security | `agents/03_build/rules/swift-security.md` | Handling credentials, network, privacy manifests |
| Swift testing | `agents/03_build/rules/swift-testing.md` | Writing unit tests |
| SwiftUI patterns | `agents/03_build/skills/swiftui-patterns.md` | UI-heavy features with DesignSystem |
| Build error resolver | `agents/03_build/build_error_resolver.md` | When xcodebuild fails |
| Verification loop | `agents/03_build/skills/verification-loop.md` | Post-implementation quality checks |
| Aesthetics guide | `agents/03_build/rules/aesthetics.md` | UI polish, animations, visual hierarchy |

**Never load all rules at once.** Load the specific rule file when entering that work area.

## Pipeline Phases (Enhanced 12-Phase)

| Phase | Agent | Directory | Model | Cost Tier | NEW? |
|-------|-------|-----------|-------|-----------|------|
| 1 | Deep Research | `agents/01_research/` | sonnet | $$ | Enhanced |
| 2 | Validation | `agents/02_validation/` | haiku | $ | — |
| 3 | Build | `agents/03_build/` | sonnet | $$ | Enhanced |
| 4 | Code Review | `agents/04_code_review/` | sonnet | $$ | **NEW** |
| 5 | Quality | `agents/05_quality/` | haiku | $ | Enhanced |
| 6 | Monetization | `agents/06_monetization/` | sonnet | $$ | — |
| 7 | App Store Prep | `agents/07_appstore_prep/` | haiku | $ | — |
| 8 | Onboarding | `agents/08_onboarding/` | sonnet | $$ | — |
| 9 | Screenshots | `agents/09_screenshots/` | haiku | $ | — |
| 10 | Promo | `agents/10_promo/` | haiku | $ | Enhanced |
| 11 | Launch | `agents/11_launch/` | sonnet | $$ | **NEW** |
| 12 | Growth | `agents/12_growth/` | haiku | $ | **NEW** |

### What Changed (v2 Pipeline)

**Phase 1 — Deep Research** (was: basic Brave Search)
- Added: Scrapling web scraping for App Store competitor analysis, Reddit thread mining, review extraction
- Added: Structured competitor feature matrix (not just names)
- Added: Real user complaint extraction from forums/reviews
- Enhanced: Market sizing now requires 3+ independent sources

**Phase 3 — Build** (was: single-pass generation)
- Added: Evaluator-optimizer loop from claude-cookbooks (targeted fixes, not full rebuilds)
- Added: Context compaction checkpoints after each sub-phase (Models done → checkpoint → Views)
- Added: Build context resume via `build_context.json`
- Enhanced: everything-claude-code error resolver patterns integrated

**Phase 4 — Code Review** (NEW)
- Dedicated security audit (AgentShield 102-rule scanner from everything-claude-code)
- Architecture review: MVVM compliance, DesignSystem usage, view size limits
- Accessibility audit: VoiceOver labels, Dynamic Type, contrast ratios
- Performance review: memory leaks, unnecessary redraws, large allocations
- Output: `code_review.json` with findings + severity + file:line references

**Phase 5 — Quality** (renumbered from 4, enhanced)
- Added: Evaluator-optimizer loop (targeted fix → re-check, not full rebuild)
- Added: iOS Simulator automated testing (from awesome-claude-skills)
- Enhanced: AgentShield security patterns inform security_check.sh
- Enhanced: Fix loop runs up to 5 targeted iterations before declaring failure

**Phase 10 — Promo** (renumbered from 9, enhanced)
- Added: Twitter Algorithm Optimizer (from awesome-claude-skills)
- Added: SEO-optimized blog post draft
- Added: App Store review response templates
- Enhanced: Social posts optimized for each platform's algorithm

**Phase 11 — Launch** (NEW — from MoneyPrinterV2 + Larry/OpenClaw)
- Automated social media posting via CRON scheduling
- YouTube Shorts generation from video_prompt.md
- Cold email outreach to press/influencers from email_templates.md
- Product Hunt launch preparation
- Reddit seeding strategy execution
- **NEW: Larry-style autonomous content engine** (`orchestrator/content_engine.sh`)
  - Self-learning `content/RULES.md` with hook formulas (updated by analytics)
  - 7-post weekly batches with A/B variant testing
  - TikTok draft posting (human adds trending audio)
  - Hook formulas: Third-Party Conflict, Before/After, Secret/Discovery
- Output: `launch_report.json` with published URLs and metrics

**Phase 12 — Growth** (NEW — with self-learning content loop)
- ASO iteration based on keyword ranking data
- App Store review monitoring and response generation
- Feature request extraction from reviews
- A/B test recommendations for screenshots and descriptions
- Revenue analytics and pricing optimization suggestions
- Competitor monitoring for new features/pricing changes
- **NEW: Autonomous content loop** (generates → posts → analyzes → learns → repeats)
  - 2x2 performance matrix: views × conversions → scale/fix/retire decisions
  - `content/LEARNINGS.md` accumulates patterns over time (like Larry's 500+ rules)
  - Content volume ramps: 7/week → 14/week → 21/week as rules improve
  - RevenueCat integration for conversion tracking (when configured)
- Output: `growth_plan.json` with prioritized actions

### Phase Migration Map (Old → New)

| Old Phase | Old # | New Phase | New # |
|-----------|-------|-----------|-------|
| Research | 1 | Deep Research | 1 |
| Validation | 2 | Validation | 2 |
| Build | 3 | Build | 3 |
| — | — | Code Review | 4 |
| Quality | 4 | Quality | 5 |
| Monetization | 5 | Monetization | 6 |
| App Store Prep | 6 | App Store Prep | 7 |
| Onboarding | 7 | Onboarding | 8 |
| Screenshots | 8 | Screenshots | 9 |
| Promo | 9 | Promo | 10 |
| — | — | Launch | 11 |
| — | — | Growth | 12 |

## Routing Rules

1. Read the project's `state.json` to determine current phase
2. Load ONLY the corresponding `agents/XX/AGENT.md` for that phase
3. Execute the agent with minimal project context (state.json + phase-specific files only)
4. On success: advance `state.json` to the next phase
5. On failure: use evaluator-optimizer loop for targeted fixes (up to 5 iterations)
6. If targeted fixes exhaust: increment `fail_count`, log to `logs/failures.jsonl`
7. If `fail_count >= 3`: set status to `paused` for manual review

## Model Selection (Cost-Optimized)

- **Haiku** ($1/$5 per 1M tokens): Validation, quality, app store prep, screenshots, promo, growth
- **Sonnet** ($3/$15 per 1M tokens): Research, build, code review, monetization, onboarding, launch
- **Opus** ($15/$75 per 1M tokens): Reserved for complex SwiftUI escalation only
- Model router: `source orchestrator/model_router.sh` then `MODEL=$(get_model "phase_name")`

## Integrated Tools

### Scrapling (Deep Research)
- Path: `tools/scrapling/`
- Used in: Phase 1 (Deep Research)
- Capabilities: App Store scraping, Reddit mining, competitor review extraction, anti-bot bypass
- Wrapper: `orchestrator/scrapling_search.sh`

### AgentShield (Security)
- Integrated into: Phase 4 (Code Review) and Phase 5 (Quality)
- 102-rule security scanner from everything-claude-code
- Checks: secrets detection (14 patterns), permission auditing, hook injection, iOS-specific vulnerabilities

### MoneyPrinterV2 (Launch Automation)
- Path: `tools/moneyprinter/`
- Used in: Phase 11 (Launch)
- Capabilities: Twitter CRON posting, YouTube Shorts generation, cold email outreach
- Note: Replace gpt4free with Claude/Qwen calls. AGPL license — modifications must be open-sourced.

### Evaluator-Optimizer Loop (from claude-cookbooks)
- Used in: Phase 3 (Build), Phase 4 (Code Review), Phase 5 (Quality)
- Pattern: On failure, generate structured feedback → targeted fix agent → re-check only failing items
- Max iterations: 5 per phase before declaring failure

## Research Tools

- **Brave Search API**: Integrated in research agent via `orchestrator/brave_search.sh`
  - `brave_web_search "query"` — general web search
  - `brave_app_research "topic"` — app store + reddit + market data
  - `brave_trending_ideas "category"` — trending app opportunities
  - Two API keys rotate for rate limit resilience
- **Scrapling**: Deep web scraping via `orchestrator/scrapling_search.sh`
  - `scrape_app_store "competitor_name"` — full App Store listing extraction
  - `scrape_reddit_thread "url"` — full thread with comments
  - `scrape_reviews "app_id"` — competitor review mining

## Safety Constraints

- Never commit API keys, secrets, or credentials to any project
- All secrets referenced via environment variables or Keychain
- Never force-push or delete branches without explicit user approval
- Max 5 concurrent projects to manage costs
- Log all decisions to `logs/decisions.jsonl` with reasoning
- Log all costs to `logs/costs.jsonl` for economic tracking
- If total daily cost exceeds $50, pause all non-critical work and alert
- AgentShield security scan must pass before any app reaches Phase 6 (Monetization)

## File Conventions

- State files: JSON (`projects/<name>/state.json`)
- Logs: JSONL append-only (`logs/*.jsonl`) — **NEVER overwrite or truncate JSONL files. Only append.**
- Config: YAML (`orchestrator/config.yaml`, agent configs)
- Templates: In each agent's `templates/` directory
- Each JSONL file starts with a `_schema` line defining its structure. Read the schema before appending.

## Context Budget (Token Optimization)

- Orchestrator cycle: keep under 5% of context window
- Load L3 (project files) ONLY when actively working on that project
- Prefer reading `state.json` summaries over full source trees
- Each agent prompt should be < 8KB. Include only:
  1. AGENT.md instructions
  2. state.json
  3. Phase-specific files (one-pager for build, not entire source tree)
- **Progressive disclosure for rules**: Load `rules/*.md` and `skills/*.md` only when entering that work area
- **Context compaction**: After each build sub-phase, write `build_context.json` checkpoint
- **Prompt caching**: Pre-concatenate AGENT.md + active rules into single cached system prompt per phase

## User Ideas

- Users drop `.md` files into `ideas/` directory
- These get priority over autonomous research findings
- Format: see `ideas/README.md`

## Cost Tracking

Every Claude API call logs to `logs/costs.jsonl`:
```json
{"timestamp": "ISO8601", "project": "AppName", "agent": "03_build", "model": "haiku", "input_tokens": 0, "output_tokens": 0, "cost_usd": 0.00}
```

## Revenue Tracking

All apps use StoreKit 2 under the user's Apple Developer account.
Revenue flows: User Purchase -> Apple (15% cut) -> User's bank account.
