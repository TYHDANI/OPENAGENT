# Komainu (Koma) — AI Cognitive Firewall

## Elevator Pitch
"CrowdStrike for the human mind." A browser extension + iOS app that detects psychological manipulation in real-time, builds your personal cognitive vulnerability profile, and alerts you to coordinated narrative campaigns before they influence your decisions. The first consumer-grade cognitive security product.

## The Problem
Zero consumer-grade tooling exists for detecting when you're being psychologically manipulated online. No dashboard, no alerts, no training. The DoD/DARPA funds this exact research but none of it reaches regular people. AI-generated influence content is now trivially cheap to produce at scale, public awareness is rising, and regulatory momentum (EU AI Act, FEC ad disclosure) is building. 18-month window before the space gets crowded.

## Core App Concept

### Layer 1: Browser Extension (Chrome/Safari)
- Real-time content analysis as you browse
- Flags known manipulation patterns: emotional hijacking, tribal identity appeals, artificial urgency, coordinated narrative pushes
- Orange badge notification: "Manipulation pattern detected"
- One-tap "Mark as psyop" or "Dismiss" for crowdsourced threat intel
- Campaign detection: "This narrative appeared on 340 accounts in the last 6 hours. Likely coordinated."

### Layer 2: iOS Companion App
- **Cognitive Vulnerability Score (CVS)** — Personal profile built over time mapping your specific susceptibility patterns
- **Threat Dashboard** — Weekly digest of manipulation attempts you encountered
- **Adversarial Training** — Duolingo-style daily sessions exposing manipulation tactics, calibrated to YOUR weak points
- **Campaign Network View** — Visualize coordinated narratives spreading in real-time
- **Weekly Threat Digest** — "You were exposed to 47 flagged narratives this week"

### Layer 3: Enterprise/B2B Platform
- Security team dashboard with org-wide threat exposure heatmap
- Slack/Teams bot alerting executives when they're being targeted
- SIEM integration (Splunk, Sentinel, QRadar, CrowdStrike Falcon)
- MITRE ATT&CK mapping for social engineering and influence operations

## Target Users
- **B2C**: Privacy-conscious professionals, journalists, political analysts, executives
- **B2B Teams**: Newsrooms, financial analysts, political campaigns ($299/mo per 10 seats)
- **Enterprise**: Law firms, financial institutions, hedge funds ($2,500-15,000/mo)
- **Government**: DoD, DHS, CISA, allied governments ($250K-2M/year)

## Revenue Model (iOS App)
- **Free Tier**: Browser extension with basic manipulation flags (acquisition funnel)
- **Pro**: $29/month — Full CVS profile, training, campaign alerts, mobile app
- **Teams**: $299/month per 10 seats — Newsrooms, financial analysts
- Premium IAP in iOS app for Pro tier via StoreKit 2

## Monetization Beyond Subscriptions
- **B2B2C Distribution**: White-label for banks (fraud prevention), antivirus bundles, financial institutions
- **Insurance**: Cyber insurers embed CVS into underwriting models (pay per policy assessed)
- **Training Data**: Labeled manipulation examples dataset ($5-50M value to AI safety companies)
- **Government Contracts**: CISA approved product list → 430 federal agencies
- **Political Intelligence**: $25-100K/campaign cycle for real-time narrative monitoring

## Key iOS Features
1. **CVS Dashboard** — Your cognitive vulnerability score with trend graph
2. **Daily Training** — 5-min adversarial critical thinking challenges
3. **Threat Feed** — Real-time flagged narratives from your browsing
4. **Campaign Map** — Network visualization of coordinated influence ops
5. **Weekly Digest** — Push notification summary with actionable insights
6. **Settings Sync** — Extension ↔ app seamless experience
7. **Offline Training** — Downloaded training modules for airplane mode
8. **Share Report** — Export threat exposure reports as PDF

## Competitive Landscape
- **Cyabra** — B2B only, $168M raised, coordinated disinformation detection for gov/brands
- **Primer** — B2B only, NLP tech for defense/intelligence agencies
- **KnowBe4** — $4.6B acquisition, security awareness training (phishing only, no cognitive layer)
- **Proofpoint** — $12.3B, email security + phishing (no human-layer detection)
- **NO consumer product exists** with meaningful revenue in cognitive defense

## The MOAT
1. **Proprietary Behavioral Data** — Longitudinal cognitive profiles take months to build. After 90 days, massive switching cost
2. **Network Effects** — More users = better campaign detection (coordinated psyops detected faster)
3. **Methodology IP** — Partner with academic researchers, lock in proprietary CVS scoring models
4. **Regulatory Tailwind** — EU AI Act, FEC AI disclosure mandates → be the trusted infrastructure
5. **Taxonomy Ownership** — Publish the canonical taxonomy of manipulation tactics (like MITRE ATT&CK for cognitive attacks)

## Technical Stack (iOS)
- SwiftUI for dashboard, training UI, campaign visualization
- Core ML for on-device content analysis (privacy-first)
- Safari Web Extension for browser integration
- CloudKit for profile sync
- Push notifications for real-time threat alerts
- Charts framework for CVS trends and campaign visualizations
- StoreKit 2 for Pro subscription

## Revenue Projections
- Y1: 500 Pro + 20 Teams → ~$245K ARR
- Y2: 2K Pro + 100 Teams + 5 Enterprise → ~$1.4M ARR
- Y3: 5K Pro + 300 Teams + 20 Enterprise → ~$4.8M ARR
- Y4: Scale + 2 Gov contracts → ~$12M ARR
- Exit: Strategic acquisition target at ~$25M ARR → $200-300M (CrowdStrike, Cloudflare, Palantir)

## Go-To-Market Strategy
1. Ship free browser extension + iOS app with CVS score (acquisition)
2. Publish cognitive manipulation taxonomy as academic paper (IEEE Security)
3. Launch free CVI assessment tool (viral through controversy)
4. Get first paying B2B customers: newsrooms, political consultants
5. Bank/insurer white-label deals for distribution
6. File MITRE ATT&CK mapping, start CISA approval process
7. SIEM integrations for enterprise security stacks

## Risk Assessment
- Consumer willingness-to-pay is low for "anti-misinformation" (Truepic CEO confirmed this)
- **Mitigant**: Frame as security/privacy, not misinformation. B2B2C distribution via banks/insurers
- AI inference layer requires fine-tuned models, not just prompting
- Network effects take 12-18 months to kick in
- Web3/token layer adds complexity — keep consumer experience wallet-free

## Confidence: 8.5/10
Strong concept, massive TAM ($17B cognitive security market → $46B by 2030), regulatory tailwind, no consumer competitor. Main risk: consumer WTP. Solution: B2B-first with consumer as data flywheel.

## Name Rationale
"Komainu" — the guardian lion-dogs of Japanese shrines. They guard sacred spaces from evil spirits. Your app guards the mind from manipulation. Short form: "Koma."
