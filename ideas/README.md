# App Ideas

Drop `.md` files here with your app ideas. The research agent checks this directory first — user ideas always get priority over autonomous research.

## Format

Create a file named `your-app-idea.md` with the following structure:

```markdown
# App Name

## Problem
What problem does this app solve? Who has this problem?

## Solution
How does the app solve it? Key features (3-5 bullet points).

## Target Audience
Who will use this? Age range, demographics, interests.

## Monetization
How should it make money? (subscription, one-time purchase, freemium)
Suggested price point if any.

## Competition
Any known competitors? What makes this different?

## Notes
Any additional context, inspiration, or requirements.
```

## Quick Add

Use the helper script:
```bash
./scripts/add_idea.sh "My App Name"
```

This creates a properly formatted template you can fill in.

## What Happens Next

1. LITTLEGREENMAN (orchestrator) picks up your idea on the next 5-minute cycle
2. A project is created in `projects/your-app-name/`
3. The idea file is renamed to `.processed`
4. The pipeline runs: validation → build → quality → monetization → App Store
