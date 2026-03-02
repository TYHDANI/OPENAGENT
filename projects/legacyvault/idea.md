# Crypto iOS App Analysis — Top 3 Picks for OPENAGENT

## Source Material
- **PDF**: iTrustCapital Competitor Analysis (68 pages) — covers crypto IRA landscape, competitor weaknesses, app/token/service opportunities across digital asset custody, tax-advantaged crypto, altcoin lending, estate planning, and yield monitoring.
- **Expert Feedback**: Refined critique emphasizing defensibility, cross-platform moats, and the "service -> software -> protocol" build pipeline.

## Selection Criteria
1. **Defensible** — cannot be cloned as a feature update by iTrustCapital, Coinbase, or Kraken
2. **Buildable** — SwiftUI MVP in 2-3 weeks, 10-14 screens
3. **Revenue in 30 days** — subscription or retainer model, not "build audience first"
4. **Clear moat** — cross-platform data aggregation, intelligence layer, or integration depth

---

# APP 1: LegacyVault — Cross-Platform Crypto Estate Orchestration

## One-Line Pitch
The only app that monitors wallet activity across every exchange, IRA custodian, and self-custody wallet — and automatically executes your crypto succession plan when you can't.

## Why It's Defensible (Moat)
No single platform (iTrustCapital, Coinbase, Kraken) has incentive or ability to monitor *competitor* platforms. LegacyVault sits **above** all of them as an orchestration layer. The moat compounds with every integration added — each new exchange/custodian API connection makes the product harder to replicate. The intelligence layer (dormancy detection, incapacitation triggers, multi-platform beneficiary routing) requires cross-platform data that no single custodian possesses.

Key moat components:
- Read-only API connections to 10+ exchanges and custodians simultaneously
- On-chain wallet monitoring for self-custody (BTC, ETH, SOL addresses)
- Dormancy detection algorithms (no activity for X days = trigger review)
- Multi-signature beneficiary verification (biometric + trusted contact confirmation)
- Legal document integration (will/trust references, attorney contact automation)

## Core Features (MVP — 12 Screens)

1. **Dashboard** — Total estate value across all connected platforms, health status indicators, last-activity timestamps per account
2. **Connect Accounts** — Add exchange API keys (read-only), IRA custodian logins (Plaid/OAuth), paste wallet addresses for on-chain monitoring
3. **Account Detail** — Per-platform holdings breakdown, last transaction, dormancy timer status
4. **Succession Plan Builder** — Assign beneficiaries to specific accounts/assets, set trigger conditions (dormancy period, dead-man switch interval, trusted contact confirmation)
5. **Beneficiary Manager** — Add/edit beneficiaries with contact info, identity verification, assign % splits or specific assets
6. **Trusted Contacts** — Designate 2-3 people who can confirm incapacitation (requires 2-of-3 to trigger)
7. **Activity Monitor** — Timeline of all detected transactions across platforms, anomaly alerts (unexpected large transfers)
8. **Dead-Man Switch** — Configurable check-in interval (weekly/monthly), missed check-in escalation flow (SMS -> email -> trusted contact -> trigger plan)
9. **Document Vault** — Encrypted storage for will excerpts, trust documents, attorney contact info, access instructions
10. **Emergency Access** — What beneficiaries see: step-by-step instructions per platform, legal requirements, contact info
11. **Notifications & Alerts** — Dormancy warnings, check-in reminders, price alerts on estate value, security alerts
12. **Settings & Subscription** — Account management, subscription tier, security preferences, data export

## Monetization Model

| Tier | Price | Included |
|------|-------|----------|
| **Basic** | Free | 2 connected accounts, 1 beneficiary, monthly check-in only |
| **Guardian** | $9.99/mo ($99/yr) | 10 accounts, 5 beneficiaries, weekly check-in, document vault, activity monitor |
| **Estate** | $29.99/mo ($299/yr) | Unlimited accounts, unlimited beneficiaries, daily monitoring, trusted contacts, priority alerts, legal document templates |
| **Family Office** | $99.99/mo ($999/yr) | Multi-user access, entity-level organization, attorney dashboard access, API, white-glove onboarding call |

**Pricing basis**: Charge on monitoring scope, not estate value (avoids AUM-fee regulatory complexity at launch). Upgrade path to value-based pricing in Year 2 once established.

## Year 1 Revenue Projection

| Scenario | Paid Users by Month 12 | Avg Revenue/User/Mo | Monthly Revenue | Annual Revenue |
|----------|------------------------|---------------------|-----------------|----------------|
| **Conservative** | 500 | $18 | $9,000 | ~$65,000 |
| **Moderate** | 2,000 | $22 | $44,000 | ~$320,000 |
| **Aggressive** | 5,000 | $25 | $125,000 | ~$900,000 |

Conservative assumes organic App Store discovery + crypto Reddit/Twitter marketing only. Moderate assumes one viral "protect your crypto estate" content cycle. Aggressive assumes partnerships with 2-3 crypto estate planning attorneys who refer clients.

## Build Time Estimate
- **Week 1**: Core UI (dashboard, account connection, succession plan builder), Plaid/OAuth integration scaffolding, encrypted local storage (Keychain + Core Data)
- **Week 2**: Exchange API integrations (Coinbase, Kraken, iTrustCapital via read-only API keys), on-chain address monitoring (Blockstream/Etherscan APIs), dead-man switch logic, push notifications
- **Week 3**: Document vault, beneficiary flow, trusted contact verification, StoreKit 2 subscriptions, polish and App Store submission
- **Total**: 3 weeks

## Technical Stack
- **UI**: SwiftUI + Charts framework
- **Storage**: Core Data (encrypted) + Keychain for API keys and sensitive data
- **APIs**: Plaid (bank/custodian linking), Coinbase API, Kraken API, Blockstream API (BTC on-chain), Etherscan API (ETH on-chain), CoinGecko (pricing)
- **Notifications**: APNs + background fetch for dormancy monitoring
- **Auth**: Sign in with Apple + biometric (Face ID/Touch ID)
- **Backend**: CloudKit (sync between devices) or lightweight Vapor server for check-in timer persistence
- **Encryption**: CryptoKit for document vault encryption

---

# APP 2: YieldSentinel — Real-Time Credit Ratings for Crypto Yield Products

## One-Line Pitch
A Bloomberg Terminal-style monitoring service that continuously rates the health of every crypto yield product — collateral ratios, reserve audits, on-chain flows — and alerts you before the next Celsius happens.

## Why It's Defensible (Moat)
This is NOT a comparison site (those are trivially cloneable). YieldSentinel is a **continuous monitoring and rating system** — a "Moody's for DeFi." The moat is the proprietary risk model trained on historical collapse data (Celsius, Voyager, BlockFi, Terra/Luna, FTX) combined with real-time on-chain data feeds. No exchange or custodian will build this because it requires rating *their competitors* and potentially issuing negative ratings on their own products. Institutional investors (crypto funds, family offices, RIA firms) will pay for independent risk intelligence.

Key moat components:
- Proprietary risk scoring algorithm (0-100 "Sentinel Score") based on 15+ on-chain and off-chain signals
- Historical training data from every major crypto yield collapse since 2020
- Real-time on-chain monitoring of protocol TVL, collateral ratios, whale movements, bridge flows
- Off-chain signals: audit status, team transparency, regulatory filings, social sentiment
- Alert system that detected Celsius-type patterns weeks before collapse (tested against historical data)

## Core Features (MVP — 11 Screens)

1. **Dashboard** — Watchlist of monitored yield products with live Sentinel Scores, color-coded risk levels (green/yellow/orange/red), portfolio-weighted risk score
2. **Product Detail** — Deep-dive on any yield product: current APY, Sentinel Score breakdown by factor, historical score chart, collateral composition, audit status, team info
3. **Risk Factors** — Breakdown of 15+ risk signals for each product: TVL trend, collateral ratio, reserve proof, audit recency, regulatory status, social sentiment, whale concentration, smart contract risk, bridge dependency, team doxxing level, insurance coverage, withdrawal processing time, historical drawdown, peer comparison, liquidity depth
4. **Alerts Center** — All triggered alerts with severity levels, configurable alert thresholds per product (e.g., "alert me if Sentinel Score drops below 60")
5. **Portfolio Tracker** — Input your yield positions across platforms, see aggregate risk exposure, concentration warnings, suggested rebalancing
6. **Historical Analysis** — How past collapses scored in the weeks/months before failure (Celsius timeline, Voyager timeline, etc.) — proves the model works
7. **Leaderboard** — Ranked list of all monitored yield products by Sentinel Score, filterable by type (lending, staking, LP, structured), chain, APY range
8. **Research Reports** — Monthly "State of Yield" reports, deep-dives on specific protocols, regulatory landscape updates
9. **Compliance Filter** — For IRA/tax-advantaged accounts: filter yield products by regulatory status, show which are compatible with self-directed IRA custodians
10. **News & Events** — Aggregated news feed filtered for yield-relevant events, regulatory announcements, protocol updates
11. **Settings & Subscription** — Account, alert preferences, notification channels (push, email, SMS), subscription management

## Monetization Model

| Tier | Price | Included |
|------|-------|----------|
| **Free** | $0 | View top 10 yield products, delayed scores (24h lag), 1 alert |
| **Analyst** | $14.99/mo ($149/yr) | All products, real-time scores, 10 alerts, portfolio tracker, historical analysis |
| **Professional** | $49.99/mo ($499/yr) | Everything + research reports, compliance filter, SMS alerts, API access (100 calls/day), export |
| **Institutional** | $499/mo ($4,999/yr) | Everything + unlimited API, custom risk models, team seats, Slack/webhook integrations, dedicated support |

## Year 1 Revenue Projection

| Scenario | Paid Users by Month 12 | Avg Revenue/User/Mo | Monthly Revenue | Annual Revenue |
|----------|------------------------|---------------------|-----------------|----------------|
| **Conservative** | 300 | $25 | $7,500 | ~$55,000 |
| **Moderate** | 1,500 | $35 | $52,500 | ~$380,000 |
| **Aggressive** | 4,000 | $40 | $160,000 | ~$1,150,000 |

Conservative assumes niche crypto-native audience. Moderate assumes coverage by crypto media after publishing first "we predicted X" case study. Aggressive assumes 5-10 institutional subscribers at $499/mo plus strong retail base.

## Build Time Estimate
- **Week 1**: Core UI (dashboard, product detail, risk factors), CoinGecko/DeFiLlama API integration for TVL and protocol data, scoring algorithm v1 (rule-based with weighted factors)
- **Week 2**: Alert system, portfolio tracker, historical analysis (backtest against Celsius/Voyager/BlockFi data), on-chain monitoring integration (Etherscan, Dune Analytics APIs)
- **Week 3**: Research report templates, compliance filter, StoreKit 2, App Store prep, polish
- **Total**: 3 weeks

## Technical Stack
- **UI**: SwiftUI + Charts framework (heavy use of time-series charts, heatmaps)
- **Data**: DeFiLlama API (TVL, protocol data), CoinGecko API (pricing), Etherscan/Blockstream APIs (on-chain), DefiSafety (audit data)
- **Scoring Engine**: On-device Core ML model for score calculation, updated weekly via CloudKit
- **Alerts**: APNs + background fetch, optional Twilio SMS for Professional tier
- **Storage**: Core Data for watchlists and portfolio, CloudKit for sync
- **Auth**: Sign in with Apple
- **Backend**: Lightweight Vapor/Supabase for score computation pipeline (some on-chain queries too heavy for on-device)

---

# APP 3: TreasuryPilot — Multi-Entity Crypto Tax & Compliance Dashboard

## One-Line Pitch
The only app that gives family offices, trusts, and multi-LLC structures a single pane of glass for crypto holdings across entities — with real-time tax-lot tracking, automated quarterly estimated tax calculations, and consolidated reporting.

## Why It's Defensible (Moat)
No exchange or custodian handles multi-entity structures because they see one account at a time. CoinTracker and Koinly handle individual tax reporting but choke on entity structures (3 LLCs + a trust + a personal IRA, each with different tax treatment, different cost basis methods, different reporting requirements). The moat is the **entity-relationship model** — understanding how a family office's trust owns LLC A which holds BTC on Coinbase, while LLC B holds ETH on Kraken, while the personal IRA holds both on iTrustCapital, and all three need consolidated reporting with different tax treatments. This requires deep domain knowledge of entity taxation that generic crypto tax tools don't have.

Key moat components:
- Multi-entity hierarchy modeling (trust -> LLC -> individual, with nested ownership percentages)
- Per-entity tax-lot tracking with correct cost basis method per entity (FIFO, LIFO, specific ID, HIFO)
- Automated quarterly estimated tax calculations per entity
- Cross-entity wash sale detection (critical for related entities under common control)
- Multi-custodian data aggregation with entity-level tagging
- Sub-user access control (accountant sees all entities, LLC manager sees only their entity, beneficiary sees read-only)

## Core Features (MVP — 13 Screens)

1. **Entity Dashboard** — Top-level view of all entities (Trust, LLC A, LLC B, Personal), aggregate holdings, per-entity performance, tax liability summary
2. **Entity Detail** — Holdings for one entity, connected accounts, cost basis summary, unrealized gains/losses, current-year realized gains
3. **Entity Setup** — Create entity (LLC, Trust, S-Corp, Individual, IRA), set tax treatment, cost basis method, fiscal year, ownership structure
4. **Connect Accounts** — Link exchange/custodian accounts and tag them to specific entities (same Plaid/API approach as LegacyVault)
5. **Transaction Ledger** — All transactions across all entities, filterable by entity/account/asset/date, auto-categorized (buy, sell, transfer, income, fee)
6. **Tax-Lot Viewer** — Per-asset lot breakdown showing acquisition date, cost basis, current value, holding period (short/long-term), per-entity
7. **Quarterly Estimates** — Automated Q1/Q2/Q3/Q4 estimated tax calculations per entity, based on realized gains YTD, with payment due date reminders
8. **Consolidated Report** — Cross-entity summary report: total holdings, total gains/losses, entity-by-entity breakdown, exportable PDF
9. **Wash Sale Monitor** — Flags potential wash sales across related entities (30-day window), critical for entities under common control
10. **User & Role Management** — Invite accountant, attorney, entity manager with role-based access (admin, manager, viewer)
11. **Tax Calendar** — Filing deadlines per entity type, estimated payment dates, extension deadlines, audit-relevant dates
12. **Document Export** — Generate Form 8949, Schedule D data, K-1 summaries, custom CSV exports for accountants
13. **Settings & Subscription** — Account, entity management, subscription, integrations

## Monetization Model

| Tier | Price | Included |
|------|-------|----------|
| **Starter** | Free | 1 entity, 2 connected accounts, basic tax tracking, no exports |
| **Professional** | $29.99/mo ($299/yr) | 3 entities, 10 accounts, quarterly estimates, PDF reports, 1 additional user |
| **Family Office** | $79.99/mo ($799/yr) | 10 entities, unlimited accounts, all reports, wash sale detection, 5 users, Form 8949 export, priority support |
| **Enterprise** | $199.99/mo ($1,999/yr) | Unlimited entities/accounts/users, API access, custom reports, dedicated onboarding, accountant portal |

## Year 1 Revenue Projection

| Scenario | Paid Users by Month 12 | Avg Revenue/User/Mo | Monthly Revenue | Annual Revenue |
|----------|------------------------|---------------------|-----------------|----------------|
| **Conservative** | 200 | $55 | $11,000 | ~$80,000 |
| **Moderate** | 800 | $65 | $52,000 | ~$375,000 |
| **Aggressive** | 2,000 | $75 | $150,000 | ~$1,080,000 |

This is a higher-ARPU, lower-volume product. Conservative assumes direct outreach to crypto-focused CPAs and estate attorneys. Moderate assumes App Store presence + CPA referral program. Aggressive assumes strategic partnership with 1-2 crypto custodians who refer multi-entity clients.

## Build Time Estimate
- **Week 1**: Entity hierarchy model and Core Data schema, entity setup/detail screens, account connection (Plaid + exchange APIs), transaction import and categorization
- **Week 2**: Tax-lot engine (FIFO/LIFO/HIFO/Specific ID), quarterly estimate calculator, wash sale detection, consolidated report generation (PDF via UIKit rendering)
- **Week 3**: User/role management, document export (Form 8949 CSV, Schedule D summary), StoreKit 2, polish, App Store submission
- **Total**: 3 weeks

## Technical Stack
- **UI**: SwiftUI + Charts (portfolio charts, gain/loss visualizations)
- **Tax Engine**: Custom on-device tax-lot calculation engine, built in Swift (no external dependency — this IS the IP)
- **APIs**: Plaid (custodian linking), Coinbase/Kraken/iTrustCapital APIs (transaction history), CoinGecko (historical pricing for cost basis)
- **Storage**: Core Data (entity hierarchy, transactions, tax lots), Keychain (API keys), CloudKit (multi-device sync)
- **Export**: PDFKit for report generation, CSV export for accountant handoff
- **Auth**: Sign in with Apple + role-based access via CloudKit sharing
- **Backend**: CloudKit for sync + sharing, or lightweight Supabase for multi-user collaboration

---

# Comparison Matrix

| Factor | LegacyVault | YieldSentinel | TreasuryPilot |
|--------|------------|---------------|---------------|
| **Defensibility** | Very High (cross-platform integration moat) | High (proprietary risk model + historical data) | Very High (multi-entity tax logic moat) |
| **Build Complexity** | Medium | Medium-High (scoring algorithm) | High (tax engine) |
| **Time to Revenue** | Fast (emotional urgency — "what happens to my crypto if I die?") | Medium (needs credibility cycle) | Fast (tax season urgency, CPAs are buyers) |
| **ARPU** | $18-25/mo | $25-40/mo | $55-75/mo |
| **TAM** | Every crypto holder with >$10K (millions) | Every yield farmer + institutional (hundreds of thousands) | Multi-entity crypto holders (tens of thousands, but high value) |
| **Build Time** | 3 weeks | 3 weeks | 3 weeks |
| **Revenue Month 1** | Yes (free trial -> paid) | Possible (needs scoring credibility) | Yes (CPAs will pay immediately before tax deadlines) |
| **Regulatory Risk** | Low | Low | Low (tool, not tax advice) |

---

# Recommended Build Order

## Priority 1: LegacyVault
**Rationale**: Largest TAM, strongest emotional hook ("protect your family"), fastest path to viral distribution (every crypto holder thinks about this but has no solution). The cross-platform integration moat gets deeper with every exchange added. Can launch a "Crypto Concierge" consulting service alongside it ($5K/year retainer for high-net-worth setup) per the expert feedback — **service funds software**.

## Priority 2: TreasuryPilot
**Rationale**: Highest ARPU, most defensible technical moat (multi-entity tax logic is genuinely hard), and there is a clear buyer persona (crypto-focused CPAs and family office managers). Tax season creates natural urgency. Can charge $299-$1,999/year from day one because the alternative is a CPA manually reconciling across 4 platforms.

## Priority 3: YieldSentinel
**Rationale**: Strongest long-term institutional play but needs a credibility-building period (publish free reports, build track record of accurate risk calls). Better as a Month 3-4 launch after LegacyVault or TreasuryPilot is generating revenue. The "credit rating agency for yield products" positioning from the expert feedback is the correct framing — but credit rating agencies need track records.

---

# Combined Strategy (Expert Feedback Integration)

Following the expert's "service -> software -> protocol" pipeline:

1. **Month 1**: Launch **Crypto Concierge** consulting service (custody architecture reviews, $5K/year retainer). Requires zero code — just expertise and a booking page. Use revenue to fund app development.
2. **Month 1-3**: Build and launch **LegacyVault** iOS app. Consulting clients become first paid subscribers and beta testers.
3. **Month 3-5**: Build and launch **TreasuryPilot**. Cross-sell to LegacyVault subscribers who have multi-entity structures.
4. **Month 5-7**: Build and launch **YieldSentinel**. By now you have 6 months of on-chain monitoring data and can show "we would have caught X."
5. **Month 8+**: Evaluate token opportunity only if regulatory clarity exists. The apps and service generate cash flow independent of any token.

---

## Notes
- All three apps share infrastructure: exchange API integrations (Coinbase, Kraken, iTrustCapital), Plaid, on-chain monitoring, CoinGecko pricing. Building LegacyVault first creates reusable modules for the other two.
- The PDF's "XRP-collateral lending desk" idea is real demand but requires lending licenses and significant capital reserves — not suitable for OPENAGENT's fast-ship model. Park it for Year 2.
- The PDF's "CryptoGuard token" concept is the weakest play given 2026 regulatory uncertainty. All three apps above generate revenue without any token.
