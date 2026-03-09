# WorldView — Real-Time Global Intelligence Dashboard

## Tagline
"See Events Before They Become News"

## One-Line Pitch
AI-powered situational awareness platform that aggregates 30+ public intelligence signals onto a 4D interactive globe — from airspace movements and GPS jamming to shipping disruptions and cyber threats — giving users the same real-time picture that nation-states have, on their iPhone and Apple Vision Pro.

## The Problem
- **Information asymmetry kills**: Traders, journalists, security professionals, and citizens learn about geopolitical events 15-60 minutes after they happen — after markets have already moved, after airspace has already closed, after shipping routes have already been disrupted.
- The gap between people who SEE events unfold and people who READ about them later is the most valuable information edge in the world.
- Existing tools are fragmented: FlightRadar24 for flights, MarineTraffic for ships, GDELT for news, USGS for earthquakes — no unified picture.
- Twitter/X is fast but noisy, unverified, and doesn't show the spatial picture.

## The Solution
WorldView pulls every public intelligence signal into a unified real-time 3D globe where you can:
- **Scrub through time** minute-by-minute and watch events unfold in 4D
- **See airspace clear** over a strike zone before breaking news banners go up
- **Track GPS interference** blinding entire regions
- **Monitor shipping fleets** scrambling at chokepoints like the Strait of Hormuz
- **Watch satellite passes** (EO and SAR) over conflict zones
- **Stream live presidential addresses** that move billions in markets
- **Get AI-synthesized briefs** of what's happening right now, not what happened 2 hours ago

## Reference Architecture
Inspired by [WorldMonitor](https://github.com/koala73/worldmonitor) — a 1000+ file open-source intelligence dashboard built by one developer that aggregates 30+ data sources across 22 services into a 3D WebGL globe.

## Target Platforms
1. **iPhone** (iOS 17+) — Primary. SwiftUI + MapKit with 3D globe, push notifications for breaking events
2. **Apple Vision Pro** (visionOS 2+) — Immersive spatial experience. Room-scale 3D globe you can walk around, pinch to zoom into conflict zones, spatial panels for data layers

## Core Features (MVP)

### 1. 4D Interactive Globe
- **3D Earth** with real-time data layers rendered on/above the surface
- **Time scrubber**: Drag to replay events minute-by-minute (last 48 hours)
- **40+ toggleable layers**: Conflicts, military flights, shipping, earthquakes, wildfires, protests, cyber threats, GPS jamming, infrastructure outages, climate anomalies
- **Smart clustering**: Zoom-adaptive marker density with Supercluster algorithm
- **Region presets**: Global, Americas, Europe, MENA, Asia-Pacific, Africa (one-tap reframe)
- **Apple Vision Pro**: Volumetric globe in shared space, gaze-based interaction, spatial panels floating around the globe

### 2. Intelligence Engine (AI-Powered)
- **World Brief**: LLM-synthesized top 5 global developments, refreshed every 15 minutes
- **Country Instability Index (CII)**: 0-100 composite score from 23 weighted signals per country
- **Focal Point Detection**: Cross-correlates military, news, protests, markets, outages to identify developing situations
- **AI Deduction**: Ask free-text geopolitical questions ("What happens if Strait of Hormuz closes?") with 15 recent headlines as context
- **Breaking Alerts**: Push notification within 60 seconds of critical events (airspace closures, GPS jamming, military escalation)

### 3. Real-Time Data Feeds (30+ Sources)

| Domain | Sources | Update Frequency |
|--------|---------|-----------------|
| Military Flights | OpenSky Network, ADS-B Exchange, Wingbits | Real-time (WebSocket) |
| Maritime/Shipping | AISStream (AIS), NGA navigational warnings | Real-time (WebSocket) |
| Conflicts | ACLED, UCDP, GDELT | 1-6 hours |
| News | 170+ RSS feeds (BBC, Reuters, Al Jazeera, Bloomberg) | 15 minutes |
| Earthquakes | USGS | 5 minutes |
| Wildfires | NASA FIRMS satellite detection | 30 minutes |
| GPS/GNSS Jamming | GPSJam.org, public interference reports | 1 hour |
| Satellite Passes | CelesTrak TLE data, Space-Track.org | 6 hours |
| Markets | Finnhub (stocks), CoinGecko (crypto), EIA (energy) | 1-15 minutes |
| Cyber Threats | Feodo Tracker, URLhaus, AbuseIPDB, OTX | 1 hour |
| Internet Outages | Cloudflare Radar | 15 minutes |
| Climate | Open-Meteo anomalies | 6 hours |
| Protests/Unrest | ACLED + GDELT | 6 hours |
| Prediction Markets | Polymarket | 15 minutes |
| Economic | FRED, BIS, World Bank | Daily |
| Displacement | UNHCR flows | Daily |
| Supply Chain | Chokepoint status, Baltic Dry Index | Daily |
| Trade Policy | WTO tariff data | Weekly |

### 4. Live Event Streaming
- **Presidential addresses** (audio stream + real-time transcript)
- **OREF-style alerts** (missile/drone warnings)
- **Airspace NOTAMs** (no-fly zone declarations)
- **Market flash crashes** (>2% index move in <5 min)

### 5. Offline & Background
- **Cached globe tiles** for offline map viewing
- **Background fetch** for data refresh every 15 minutes
- **Local notifications** for triggered alerts even when app is closed
- **On-device ML** for headline embedding + semantic search (Core ML with MiniLM)

## Apple Vision Pro Experience

### Shared Space Mode
- 3D globe floating in front of user (1.5m diameter)
- Pinch-to-zoom into regions
- Gaze at a data point → detail panel appears beside it
- Tap layers panel on the left to toggle data layers
- Time scrubber as a horizontal rail below the globe

### Immersive Mode
- Room-scale globe (fills the space)
- Walk around the globe to inspect regions
- Spatial audio: news audio positioned at geographic location
- Data layers rendered as volumetric particles above the surface
- Military flight paths as 3D arc trails
- Shipping routes as flowing particle streams

## Technical Architecture

### iOS (SwiftUI + MapKit)
```
WorldView/
├── App.swift (entry point, @Observable managers)
├── Models/
│   ├── IntelligenceModels.swift (CII, RiskScore, FocalPoint)
│   ├── MilitaryModels.swift (Flight, Base, FleetReport)
│   ├── MaritimeModels.swift (Vessel, AISDisruption, NavWarning)
│   ├── ConflictModels.swift (ACLEDEvent, UCDPEvent)
│   ├── MarketModels.swift (Quote, Commodity, Crypto)
│   ├── CyberModels.swift (Threat, IOC)
│   ├── InfraModels.swift (Outage, ServiceStatus)
│   └── NewsModels.swift (Article, FeedDigest)
├── Services/
│   ├── DataOrchestrator.swift (coordinates all feeds, manages refresh)
│   ├── WebSocketRelay.swift (OpenSky + AIS real-time)
│   ├── IntelligenceService.swift (CII calculation, focal point detection)
│   ├── NewsService.swift (RSS aggregation + AI summarization)
│   ├── CacheManager.swift (SQLite for snapshots + baselines)
│   └── NotificationService.swift (breaking event alerts)
├── Views/
│   ├── GlobeView.swift (MapKit 3D globe with custom annotations)
│   ├── TimelineView.swift (scrubber for 4D replay)
│   ├── LayerPanelView.swift (toggle 40+ data layers)
│   ├── WorldBriefView.swift (AI-synthesized summary)
│   ├── CountryDetailView.swift (CII breakdown, event history)
│   ├── EventDetailView.swift (conflict/flight/vessel/threat detail)
│   ├── AlertsView.swift (breaking events feed)
│   ├── DeductionView.swift (AI Q&A interface)
│   ├── SettingsView.swift (notification prefs, data freshness)
│   ├── PaywallView.swift (subscription tiers)
│   └── OnboardingView.swift (region selection, interests, alerts setup)
├── VisionOS/
│   ├── ImmersiveGlobeView.swift (RealityKit volumetric globe)
│   ├── SpatialPanelView.swift (floating data panels)
│   └── VolumetricLayerView.swift (3D data layer rendering)
├── ML/
│   ├── HeadlineEmbedder.swift (Core ML MiniLM-L6)
│   ├── SemanticSearch.swift (vector similarity on headlines)
│   └── EventClassifier.swift (on-device event categorization)
└── DesignSystem/
    ├── Colors.swift (dark theme: navy #0A1628, teal accents)
    ├── Typography.swift (SF Pro + SF Mono)
    └── Components/ (badges, severity indicators, data freshness pills)
```

### Data Layer Architecture
- **Tiered caching**: Hot (in-memory, <1min), Warm (SQLite, <1hr), Cold (network fetch)
- **Background refresh**: iOS BackgroundTasks framework, 15-min minimum interval
- **WebSocket relay**: Persistent connection for OpenSky + AIS (via proxy server)
- **Proto-compatible**: Swift structs mirror proto service definitions for future gRPC migration

## Monetization

### Free Tier
- 3D globe with basic layers (earthquakes, wildfires, major conflicts)
- 24-hour delayed data
- 5 daily AI deductions
- Push alerts for magnitude 6+ earthquakes only

### Analyst ($14.99/month or $119.99/year)
- All 40+ data layers
- Real-time data feeds
- Unlimited AI deductions
- Custom alert rules (geographic, severity, domain)
- 48-hour time scrubber replay
- Country CII scores

### Professional ($49.99/month or $399.99/year)
- Everything in Analyst
- 7-day time scrubber replay
- Focal point detection
- World Brief (refreshed every 15 min)
- Export snapshots (PDF, CSV)
- API access for integration
- Prediction market overlay
- Apple Vision Pro immersive mode

### Enterprise ($199.99/month)
- Everything in Professional
- 30-day historical replay
- Custom data source integration
- Multi-seat team workspace
- Priority data refresh (5-min cycle)
- Webhook alerts
- SLA guarantee (99.9% uptime)

## Competitive Analysis

| Feature | WorldView | FlightRadar24 | MarineTraffic | GDELT | Google Earth |
|---------|-----------|---------------|---------------|-------|-------------|
| 3D Globe | ✅ | ❌ (2D) | ❌ (2D) | ❌ | ✅ |
| Military Flights | ✅ | ❌ (blocked) | ❌ | ❌ | ❌ |
| Ship Tracking | ✅ | ❌ | ✅ | ❌ | ❌ |
| Conflict Data | ✅ | ❌ | ❌ | ✅ | ❌ |
| Cyber Threats | ✅ | ❌ | ❌ | ❌ | ❌ |
| AI Briefs | ✅ | ❌ | ❌ | ❌ | ❌ |
| Time Replay | ✅ | Limited | Limited | ❌ | Limited |
| Apple Vision Pro | ✅ | ❌ | ❌ | ❌ | ❌ |
| Unified View | ✅ | ❌ | ❌ | ❌ | ❌ |
| Price (Pro) | $14.99/mo | $19.99/yr | $9.99/mo | Free | Free |

## Market Sizing

| Segment | Users | Willingness to Pay |
|---------|-------|--------------------|
| OSINT enthusiasts | 500K-1M | $14.99/mo |
| Finance/trading professionals | 200K-500K | $49.99/mo |
| Journalists/media | 100K-200K | $14.99/mo |
| Security/defense consultants | 50K-100K | $49.99-$199.99/mo |
| Academic/researchers | 100K-200K | $14.99/mo |
| Preppers/situational awareness | 2-5M | Free-$14.99/mo |
| Government/military analysts | 10K-50K | $199.99/mo |

**TAM**: $2-5B (global intelligence & monitoring tools)
**SAM**: $200-500M (mobile intelligence apps)
**SOM Year 1**: $500K-$2M (conservative with organic growth)

## Revenue Projections

| Scenario | Year 1 Subscribers | ARPU | Annual Revenue |
|----------|-------------------|------|---------------|
| Conservative | 2,000 | $20/mo | $480K |
| Moderate | 10,000 | $25/mo | $3M |
| Aggressive | 50,000 | $30/mo | $18M |

## Keywords (ASO)
Primary: world monitor, global intelligence, geopolitical dashboard, real-time globe, OSINT app
Secondary: military flight tracker, ship tracker, conflict map, earthquake alert, cyber threat map
Long-tail: real-time situational awareness, 4D globe tracker, apple vision pro intelligence

## Design Language
- **Theme**: Dark (navy #0A1628 → deep space #050A14)
- **Accents**: Severity-mapped (green safe → yellow caution → orange warning → red critical)
- **Typography**: SF Pro Display (headers), SF Mono (data values, coordinates)
- **Globe**: Photorealistic Earth texture, subtle atmosphere glow, volumetric clouds
- **Vision Pro**: Translucent glass panels, spatial depth, gaze highlights

## Privacy & Legal
- No user location collected (timezone detection only, no GPS prompt)
- All data from public/open sources (OSINT)
- No classified or restricted information
- Data retention: 30 days local cache, user-deletable
- GDPR/CCPA compliant
- App Store content rating: 12+ (news, mild conflict imagery)

## Build Priority
This is a HIGH PRIORITY user idea. The combination of iOS + Apple Vision Pro makes this a potential showcase app for spatial computing. The reference repo (WorldMonitor) provides proven architecture and data source integrations to accelerate development.

## MVP Scope (Phase 3 Build Target)
1. 3D MapKit globe with 10 core layers (conflicts, military flights, earthquakes, wildfires, shipping, outages, cyber, news, markets, protests)
2. Time scrubber (last 24 hours)
3. AI World Brief (summary of top 5 events)
4. Push notifications for critical events
5. 3 region presets (Global, MENA, Europe)
6. Basic Apple Vision Pro support (shared space globe)
7. StoreKit 2 paywall (Free + Analyst + Professional)
8. Onboarding (pick interests, set alert preferences)

## Post-MVP (v1.1+)
- Full 40+ layer catalog
- 7-day time replay
- Immersive Vision Pro mode
- Focal point detection
- AI deduction chat
- Prediction market overlay
- Team workspaces
- Webhook alerts
