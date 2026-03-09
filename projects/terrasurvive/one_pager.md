# TerraSurvive — One-Pager

## Recommendation
**CONDITIONAL GO**

Conditions:
1. Strict MVP scope — Phase 1 limited to offline maps + survival guides + species data for 3-5 key regions only. Threat intelligence, climbing atlas, and night sky navigator deferred to v1.1.
2. Data engineering architecture finalized before any UI work begins — PMTiles region pack pipeline, species database schema, and offline storage budget must be proven in a prototype.
3. Complexity tier is COMPLEX. Build agent must be prepared for 8-12 weeks, not the typical 1-3 week app pipeline.

## Summary
The world's most comprehensive offline survival intelligence platform. When you're lost, stranded, or in a survival situation with no cell service, TerraSurvive provides full offline world maps, regional survival briefings drawn from military manuals (FM 21-76, SERE), dangerous/edible species identification, trail navigation, and threat awareness — all without internet. No existing app combines these capabilities in a single offline-first package.

## Problem Statement
When you are in a survival situation — lost hiking, stranded after a natural disaster, traveling in remote areas — your phone has no signal. Every existing outdoor app (AllTrails, Gaia GPS, Google Maps) requires internet for core features. Survival guides are either text-only PDFs with no maps (SAS Survival Guide app, Army Survival Handbook) or hiking apps with no survival intelligence (AllTrails, Gaia GPS). There is no single app that works completely offline AND combines maps, survival knowledge, species identification, and regional threat awareness. This gap affects 400M+ hikers globally, 50M+ preppers/survivalists in the US, and military/SAR personnel who operate in austere environments.

## Technical Feasibility
- **Framework**: SwiftUI (required), MVVM architecture
- **iOS version target**: iOS 17+ (required for MapLibre SwiftUI DSL, latest SwiftData features)
- **Key technical components**:
  - MapLibre Native iOS SDK (v6.10.0+) with PMTiles support for offline vector maps
  - PMTiles (Protomaps) for efficient offline tile storage and region-based downloads
  - SwiftData for local persistence (favorites, downloaded regions, user settings, cached species data)
  - CoreLocation for GPS (works without cell service via device GPS chip)
  - Network framework for online/offline detection and smart sync
  - StoreKit 2 for subscriptions and lifetime purchase
  - BackgroundTasks framework for region pack downloads
  - FileManager for managing large offline data files in app Documents directory
- **Data pipeline requirements**:
  - OpenStreetMap vector tiles via Geofabrik extracts converted to PMTiles per region
  - GBIF/iNaturalist species occurrence data filtered and compressed per region (~5-50MB per region)
  - US Army FM 21-76 and SERE manual content structured as searchable JSON (~2MB)
  - CIA World Factbook geographic/climate data per country (~10MB total, bundled)
  - OpenBeta climbing routes as bundled JSON (~15MB)
  - USDA PLANTS database subset for foraging (~8MB)
- **Technical risks**:
  - PMTiles regional extracts can be 200MB-2GB each. Must implement progressive download with quality tiers.
  - MapLibre Native + PMTiles on iOS is supported since 6.10.0 but has limited production apps as reference. Edge cases possible.
  - Total offline data for all regions could exceed iOS 4GB app limit. Must use on-demand resources, not bundled assets.
  - Battery drain from continuous GPS + map rendering. Needs aggressive power management.
  - Species data curation (GBIF has 2.5B+ records) requires significant filtering/aggregation pipeline built outside the app.
- **Feasibility rating**: 7

## Market Fit
- **Target audience**:
  - Primary: Hikers, backpackers, trail runners, wilderness adventurers (400M+ globally, 60M+ in US)
  - Secondary: Preppers, survivalists, bushcrafters (estimated 20M active in US per TruePrepper 2025 data)
  - Tertiary: Military personnel, search & rescue teams, emergency responders
  - Niche: Free solo climbers, off-grid travelers, expedition teams
- **TAM**: $14.1B prepper market (2024, growing at 9.5% CAGR to $26.7B by 2031) + $1.1T US outdoor recreation economy. Digital/app slice estimated at $2-5B.
- **SAM**: ~80M addressable users in US/EU who actively hike or prep and own iPhones. At $49.99/yr average, SAM is ~$4B. Realistic capture: 0.01-0.1% = $400K-$4M Year 1.
- **Top 3 competitors**:
  1. **AllTrails** — 4.9 stars, $29.99/yr. Best trail database (450K+ trails). Weakness: no survival content, no species data, offline maps are an add-on not the core experience, zero threat awareness.
  2. **Gaia GPS** — 4.7 stars, $39.99/yr. Excellent map layer catalog (USGS, satellite). Weakness: no survival intelligence, no species data, complex UI intimidates casual users, no offline survival guides.
  3. **SAS Survival Guide** — 4.5 stars, $5.99 one-time. Respected brand. Weakness: text-only, no maps at all, no regional context, no species identification, no threat layer, feels like a 2012 app.
- **Our differentiation**: The only app that combines offline maps + regional survival intelligence + military-grade guides + species identification + threat awareness. Offline-first is the core architecture, not an afterthought. All data sources are free/public domain, enabling aggressive pricing.
- **Market fit rating**: 9

## Monetization
- **Model**: Freemium with subscription + lifetime option
- **Pricing**:
  - Free: Basic survival guides (fire, water, shelter), 1 offline region, limited species data
  - Pro: $6.99/month or $49.99/year — unlimited regions, full survival library, species database, climbing atlas, threat intelligence
  - Expedition Pack: $99.99 lifetime — everything in Pro forever, full world offline data
- **Trial period**: 7-day free trial for Pro
- **Revenue estimate (Year 1)**: $39,757 net (conservative) to $397,566 net (moderate). See validation.json for detailed projections with Apple's 15% cut factored in.
- **Monetization rating**: 8

## Time Estimate
- **Build phase**: 120-180 hours (data pipeline: 40-60h, core map/offline engine: 30-40h, survival content system: 20-30h, species database: 15-20h, UI/UX: 15-20h, StoreKit/IAP: 5-10h)
- **Total pipeline**: 8-12 weeks from build start to App Store submission
- **Complexity tier**: Complex

## MVP Scope
- **Must-have features** (v1.0):
  1. Offline vector map engine with MapLibre Native + PMTiles — download region packs over WiFi, full pan/zoom/search offline
  2. GPS positioning and basic navigation (works offline via device GPS chip)
  3. Regional survival briefings — drop a pin, get biome identification, shelter advice, weather patterns, and cultural hazards for that region
  4. Survival guide library — structured content from FM 21-76 covering fire (5 methods), water purification (3 methods), basic shelter, signaling, first aid
  5. Dangerous/edible species database — wildlife and plants per region with photos, identification tips, and safety warnings (sourced from GBIF/iNaturalist/USDA)
  6. Water source finder — rivers, streams, springs, wells from OSM data with purification decision tree
  7. SOS beacon — records GPS coordinates and survival log for when signal returns
  8. Emergency contacts — pre-cached local emergency numbers per country (CIA World Factbook data)
  9. StoreKit 2 subscription and lifetime purchase with 7-day trial
  10. Onboarding flow explaining offline-first concept and region download

- **Nice-to-have features** (v1.1+):
  1. Threat intelligence layer with real-time alerts from GDACS/USGS/NOAA (online mode) and pre-cached threat data (offline mode)
  2. Rock climbing atlas from OpenBeta (100K+ routes with difficulty ratings)
  3. Night sky navigator with offline star chart for celestial navigation
  4. Foraging camera with CoreML offline plant identification
  5. AR shelter builder overlay using ARKit
  6. Community reports — crowdsourced trail conditions and wildlife sightings
  7. Dead reckoning navigation (track distance/direction without GPS)
  8. Multi-language survival terms (40+ languages)

## App Store Strategy
- **Category**: Navigation (primary), Reference (secondary)
- **Keywords**: offline maps, survival guide, hiking maps, wilderness survival, prepper app, offline GPS, trail maps, survival manual, emergency preparedness, bushcraft
- **Positioning**: "Offline survival intelligence — maps, guides, and species data that work when nothing else does."

## Risk Summary
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| PMTiles region packs too large for practical download | Medium | High | Offer quality tiers (low-res 50MB, hi-res 500MB+). Progressive download with pause/resume. |
| MapLibre Native iOS PMTiles edge cases or crashes | Low | High | Extensive testing on real devices. Fallback to MapKit with raster tiles if critical blocker. |
| Data curation pipeline takes longer than estimated | High | Medium | Start with 3 regions (US West, US East, Western Europe). Automate pipeline early. |
| App Store rejects for military/survival content | Low | High | Frame as outdoor education and emergency preparedness. Avoid weapons/combat content. |
| Users expect full world coverage at launch | Medium | Medium | Clear messaging: "region packs" model. Show coverage map in app. Roadmap transparency. |
| Battery drain from GPS + map rendering in field | Medium | High | Significant location changes API, reduced polling, map render optimization, battery saver mode. |
| Scope creep delays MVP beyond 12 weeks | High | High | Strict phase 1 / phase 2 feature split. Build agent must enforce MVP boundary. |
| Species data accuracy — wrong ID could be dangerous | Medium | High | Prominent disclaimers. Conservative identification (flag uncertainty). Link to authoritative sources. |
