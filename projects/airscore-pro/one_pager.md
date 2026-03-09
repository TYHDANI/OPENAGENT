# AirScore Pro -- One-Pager

## Recommendation
**BUILD (Conditional)** -- Strong market tailwinds, validated problem, but hardware dependency is a major risk. Recommend building the software platform with simulated/mock sensor data and a well-defined hardware API contract. Do NOT attempt to build hardware. Partner with existing sensor OEMs (Phoenix Sensors WEPS03, Sensirion SDP31) for v1 pilots. The software-only MVP is viable and demonstrable without physical sensors.

---

## Summary
AirScore Pro is a B2B SaaS platform for PE-backed HVAC consolidators (Champions Group, Redwood Services, Sila Services, Apex Service Partners, Wrench Group). IoT sensors installed during routine maintenance visits feed real-time static pressure, MERV efficiency, and filter life data for 100K+ homes back to a centralized dashboard, enabling predictive dispatch, filter subscription revenue, and portfolio-level operational intelligence.

## Problem Statement
PE-backed HVAC roll-ups (paying 15-18x EBITDA multiples) acquire dozens of local HVAC companies but lack unified visibility into equipment health across their portfolio. Technicians make reactive service calls, filters go unchanged for months, and there is no data layer connecting the fragmented fleet of residential HVAC systems. This means missed revenue from proactive maintenance, high truck roll costs, and no defensible tech moat to justify premium acquisition multiples.

**Quantified pain**: PE add-on transactions in HVAC rose 88% YoY through June 2025. These consolidators are spending billions (Sila Services sold for ~$1.5B, Apex Service Partners completed a $3.4B secondary transaction) but have no cross-portfolio technology platform for equipment intelligence. They rely on ServiceTitan for scheduling/dispatch ($250-500/tech/month) but have zero visibility into actual equipment health between service calls.

---

## Competitive Landscape (Deep Dive)

### Tier 1: Field Service Management (FSM) Platforms
| Competitor | Pricing | IoT Capability | PE Portfolio View | Threat Level |
|-----------|---------|---------------|-------------------|-------------|
| **ServiceTitan** (TTAN, $9B market cap) | $245-398/tech/month + $5K-50K implementation | None -- no sensor integration, no equipment data layer | None -- designed for single-location operators, not roll-up visibility | Medium -- complement, not competitor |
| **Housecall Pro** | $59-149/month (5 users) | None | None | Low |
| **Jobber** | $49-199/month (6 users) | None | None | Low |
| **FieldEdge** | $100/office + $125/tech/month | None | None | Low |

**Key insight**: ServiceTitan IPO'd in Dec 2024 at $9B valuation on $772M revenue. They dominate scheduling/dispatch but have ZERO IoT sensor capability. AirScore Pro positions as a complement -- the "equipment intelligence layer" that feeds ServiceTitan's dispatch queue with proactive work orders.

### Tier 2: OEM IoT Platforms (Locked to Single Brands)
| Competitor | Focus | Cross-Brand? | Residential Fleet? | Threat Level |
|-----------|-------|-------------|-------------------|-------------|
| **Trane Connect** | Commercial building management, 20K+ users | No -- Trane equipment only | No -- commercial buildings only | Low |
| **Carrier Abound Insights** | AI-powered commercial building analytics | No -- Carrier equipment only | No -- enterprise buildings | Low |
| **Resideo Pro-IQ** | Contractor tools via Honeywell Home thermostats | Limited -- Honeywell ecosystem | Emerging -- ElitePRO thermostat with Pro-IQ Services platform offers install/engage/analyze tiers | Medium |

**Key insight**: Carrier and Trane are focused on commercial buildings, not residential fleets. Resideo's Pro-IQ is the closest competitor -- it provides contractor tools through their ElitePRO thermostat, but it is locked to the Honeywell ecosystem and does not support cross-brand portfolio analytics that PE consolidators need.

### Tier 3: HVAC Diagnostic Tools
| Competitor | Focus | Pricing | Fleet Management? | Threat Level |
|-----------|-------|---------|-------------------|-------------|
| **MeasureQuick** | Technician-facing diagnostic platform, AI-powered OCR, connects to 10+ smart tool brands | Free (basic) / $49/user/month (Premier) | No -- single-job focus, not fleet | Low |
| **Aeroseal** | Duct sealing technology (complementary) | Project-based | No | None |
| **Flair Puck** | Smart thermostat/sensor for mini-splits, WiFi | $99-149 per puck (consumer) | No -- consumer product | Low |
| **Sensibo** | Smart AC control, consumer IoT | Consumer pricing | No | Low |

### Tier 4: General IoT/Predictive Maintenance
| Competitor | Focus | Pricing | HVAC-Specific? | Threat Level |
|-----------|-------|---------|----------------|-------------|
| **Siemens Senseye** | Industrial predictive maintenance at scale | Enterprise | No -- manufacturing/industrial | Low |
| **Tractian** | AI-powered fault detection with proprietary Smart Trac sensors | Enterprise | No -- industrial machinery | Low |
| **OxMaint** | IoT sensor data integrated with CMMS | Enterprise | Partially | Low |
| **Monnit** | Wireless sensors for remote monitoring (including HVAC) | Per-sensor + gateway | Partially -- general remote monitoring | Medium |

**Competitive moat assessment**: No existing platform combines (1) cross-brand IoT sensor data, (2) PE portfolio-level analytics, (3) predictive dispatch from equipment health, and (4) filter subscription revenue engine. The gap is real and validated.

---

## Market Data (Research-Validated)

### PE-Backed HVAC Consolidator Landscape (2025-2026)
| Consolidator | PE Sponsor | Scale | Valuation/Revenue | Est. Homes |
|-------------|-----------|-------|-------------------|------------|
| **Apex Service Partners** | Alpine Investors ($3.4B secondary) | 107 acquisitions, 8,000+ employees | Not disclosed (est. $1B+ revenue) | ~500K |
| **Sila Services** | Goldman Sachs Alternatives | 40+ brands, NE/Mid-Atlantic/Midwest | ~$1.5B (incl. debt) | ~300K |
| **Champions Group** | Odyssey Investment Partners | 19+ brands, 1K-5K employees | $651M revenue | ~200K |
| **Wrench Group** | Leonard Green, Oak Hill, TSG | 25 brands, 27 markets, 14 states, 7,300 employees | $1.2B raised | ~350K |
| **Redwood Services** | Altas Partners (majority) | 18 contractor businesses, 200K customers/year | ~$1.1B valuation, ~$65M EBITDA | ~200K |
| **HomeServe** | (Public/Brookfield) | 500 HVAC techs, 250K jobs/year, 113K service plans acquired (IGS) | Public company | ~300K |

**Total estimated homes serviced by top 6 PE consolidators**: ~1.85M homes/year

### Market Sizing (Updated with Real Data)
- **TAM**: $350B+ global HVAC market (2025, Kroll estimate) with mid-single-digit CAGR
- **US HVAC market**: Projected to reach $38.45B by 2030
- **SAM**: PE-backed HVAC consolidator segment -- estimated $8-12B in combined revenue across top 20 platforms, servicing ~3-5M homes/year
- **SOM (Realistic Year 1-3)**: 2-3 pilot consolidators, 10K-50K instrumented homes, $360K-$3M ARR
- **Smart/IoT HVAC segment**: $20.75B (2024), growing at 13.6% CAGR through 2030
- **Air filter market**: $16.63B (2024), growing at 8.02% CAGR to $30.83B by 2032
- **HVAC controls market**: $17.2B (2023), projected to reach $31.4B by 2028

### Revenue Per Home Economics
- Average residential HVAC maintenance contract: $175-350/year ($15-30/month)
- HVAC service call revenue: $150-500 per visit
- Filter subscription (Second Nature model): ~$20-40/filter delivery, 4-6x/year = $80-240/year/home
- Second Nature reached 100K+ subscribers before their $16.4M Series C (total funding: $36.2M)
- Predictive maintenance reduces unexpected breakdowns by 70% and lowers maintenance costs by 25% (Deloitte)

---

## Technical Feasibility (Research-Validated)

### Sensor Hardware (NOT building -- partnering/specifying)
| Component | Product | Cost (Unit) | Cost (Volume 1K+) | Notes |
|-----------|---------|------------|-------------------|-------|
| Differential pressure sensor | Sensirion SDP31-500PA | $35.14 (250 qty) | ~$25-30 (est. 1K+) | 5x8x5mm, I2C digital, reflow solderable |
| Wireless pressure sensor | Phoenix Sensors WEPS03 | Contact for pricing (est. $50-80) | Est. $30-50 | BLE or 900MHz, 2-year battery life |
| WiFi gateway | Phoenix Sensors PS9W | Contact for pricing | Est. $40-60 | Bridges sensor data to cloud |
| Complete IoT sensor package | Industry range | $160-620 per unit | $80-200 (volume) | Includes sensor + radio + housing + battery |

**Recommended approach for MVP**: Define a sensor API contract (JSON schema for static pressure, differential pressure, temperature, humidity readings). Use simulated data in the app. Partner with Phoenix Sensors or build a reference design around Sensirion SDP31 + nRF52840 (BLE 5.0) for pilot deployments.

### BLE Reliability in HVAC Environments
- **Range**: 10-100m unobstructed; 21m (70ft) max in HVAC environments with obstructions
- **Interference**: 2.4GHz band shared with WiFi, microwaves; BLE uses Adaptive Frequency Hopping (AFH) to mitigate
- **HVAC-specific challenges**: Metal ductwork, mechanical vibration, humid environments reduce signal strength
- **Mitigation**: Strategic gateway placement (one per 3-5 homes in multi-unit, one per home in single-family); 900MHz fallback (better wall penetration); WiFi direct option for homes with existing WiFi
- **Verdict**: BLE is viable for residential HVAC with proper gateway placement. WiFi preferred for single-family homes. BLE+gateway for multi-unit properties.

### iOS Core Bluetooth Limitations (Critical Finding)
- iOS background BLE scanning is "opportunistic" -- Apple controls scanning intervals, not documented
- **iOS 26 regression**: Apps using BLE may deactivate after not connecting for a while (new in iOS 26)
- CBPeripheralManager subscription notifications broken on iPhone 17 series + iOS 26.1+
- **Verdict**: The iOS app should NOT be the primary BLE gateway. Use a dedicated WiFi/cellular gateway device that pushes data to the cloud API. The iOS app consumes cloud data via REST/WebSocket, not direct BLE.

### Smart Thermostat API Integration
- **Ecobee API**: HTTP-based, JSON, supports reading temp/humidity, HVAC mode, setpoints. BUT as of March 2024, ecobee stopped accepting new developer API keys (no ETA for reopening). Existing keys still work.
- **Google Nest**: Deprecated Works with Nest API in 2020. Device Access program exists but limited.
- **Seam API**: Third-party aggregator that wraps Ecobee and other smart home APIs -- viable alternative
- **Verdict**: Do not depend on thermostat APIs for core functionality. Treat thermostat data as an enrichment layer (nice-to-have), not a dependency.

### Filter Life Prediction Algorithms
- **Physics-based models**: Pressure drop across filter correlates with particle loading. Kalman Filter (KF), Extended Kalman Filter (EKF) approaches achieve 95-97% accuracy for remaining useful life prediction.
- **ML approaches**: Pattern-based degradation prediction, 85-92% accuracy, improves with more data
- **Key inputs**: Static pressure differential, runtime hours, outdoor air quality (AQI API), MERV rating of installed filter, home square footage
- **Prediction window**: 2-6 weeks before filter change needed
- **Verdict**: Highly feasible. Start with physics-based model (pressure drop curve fitting), add ML layer as data accumulates across fleet.

### Technical Architecture (Recommended)
```
[Sensor Puck] --BLE/WiFi--> [Gateway] --HTTPS--> [Cloud API]
                                                      |
                                              [PostgreSQL + TimescaleDB]
                                                      |
                                          [REST API / WebSocket]
                                                      |
                                              [iOS Dashboard App]
                                              [Web Dashboard]
```

- **Cloud**: AWS IoT Core or Azure IoT Hub for device management
- **Database**: PostgreSQL + TimescaleDB for time-series sensor data
- **API**: REST + WebSocket for real-time alerts
- **iOS App**: SwiftUI, SwiftData for offline caching, MapKit for fleet view
- **Web Dashboard**: React/Next.js for PE executive reporting (broader reach than iOS-only)
- **ML Pipeline**: Python (scikit-learn/TensorFlow Lite) for filter life prediction, deployed as Lambda/serverless

### Feasibility Rating: 6/10
**Justification**: The software platform (dashboard, API, predictive models) is straightforward to build (8/10 feasibility). However, the hardware dependency is the bottleneck. Without physical sensors deployed, the platform has no real data. The sensor partnership/OEM path is viable but adds 6-12 months of lead time and business development work that is outside the scope of a software MVP. iOS Core Bluetooth background limitations further complicate any "phone as gateway" strategy. Rating reflects the combined software + hardware picture.

---

## Market Fit (Research-Validated)

### Target Customers (Updated)
| Consolidator | Decision Maker | Pain Point | Budget Signal |
|-------------|---------------|-----------|--------------|
| Apex Service Partners | VP Operations | 107 acquisitions, no unified equipment intelligence | $3.4B secondary -- money is available |
| Sila Services | CTO/VP Ops | 40+ brands, no cross-brand visibility | Goldman Sachs backing, ~$1.5B valuation |
| Champions Group | VP Technology | 19+ brands under one umbrella, fragmented systems | $651M revenue, Odyssey PE sponsor |
| Wrench Group | COO | 25 brands across 14 states, 7,300 employees | $1.2B raised, Leonard Green backing |
| HomeServe | VP Digital/Innovation | 500 HVAC techs, 250K jobs/year | Public company, Brookfield-backed |

### Why Now?
1. **PE consolidation is peaking**: 88% YoY increase in PE add-on HVAC deals (H1 2025). Consolidators need tech differentiation.
2. **ServiceTitan IPO created urgency**: $9B valuation proves software value in trades. PE firms now want "what's next" beyond scheduling/dispatch.
3. **Sensor costs declining**: Sensirion SDP31 at $25-35/unit makes per-home instrumentation economically viable.
4. **Predictive maintenance proven**: 70% reduction in unexpected breakdowns, 25% lower maintenance costs (Deloitte).
5. **Filter subscription model validated**: Second Nature (formerly FilterEasy) grew to 100K+ subscribers, raised $36.2M.

### Market Fit Rating: 7/10
**Justification**: The problem is real, the buyers have budget, the timing is right (PE consolidation + ServiceTitan IPO). However, B2B enterprise sales to PE-backed companies have 6-18 month sales cycles. The target customers are sophisticated buyers who will demand pilots, references, and proven ROI. The "cold start" problem is significant -- you need sensor hardware deployed to demonstrate value, but you need customer commitments to justify sensor investment. Chicken-and-egg dynamic lowers the rating.

---

## Monetization (Research-Validated)

### Pricing Model
| Tier | Price | Includes | Target |
|------|-------|---------|--------|
| **Starter** | $3/home/month | Dashboard, alerts, basic analytics | Pilot (50-200 homes) |
| **Pro** | $5/home/month | + Predictive dispatch, filter life alerts, ServiceTitan integration | Growth (200-2K homes) |
| **Enterprise** | $8/home/month | + PE reporting, custom analytics, API access, dedicated support | Scale (2K+ homes) |
| **Filter Revenue Share** | 10-15% of filter delivery revenue | Automated filter subscription engine | All tiers |

### Pricing Validation
- ServiceTitan charges $245-398/tech/month. A consolidator with 200 techs pays $49K-80K/month.
- AirScore Pro at $5/home/month on 10K homes = $50K/month. Comparable spend, different value proposition.
- Per-home pricing aligns with how PE consolidators think (portfolio of homes, not headcount).
- Filter subscription (Second Nature model) adds $80-240/year/home in gross revenue, AirScore takes 10-15% = $8-36/home/year additional.

### Revenue Projections
| Scenario | Year 1 | Year 2 | Year 3 |
|----------|--------|--------|--------|
| **Conservative** (1 pilot, 500 homes, $3/mo) | $18K ARR | $90K ARR (3K homes) | $360K ARR (10K homes) |
| **Moderate** (2 pilots, 2K homes, $5/mo) | $120K ARR | $600K ARR (10K homes) | $1.8M ARR (30K homes) |
| **Aggressive** (3 pilots, 5K homes, $5/mo + filter rev) | $360K ARR | $1.5M ARR (25K homes) | $5M ARR (75K homes) |

### Monetization Rating: 7/10
**Justification**: The per-home SaaS model is clean and scalable. Pricing is validated against ServiceTitan benchmarks. Filter subscription revenue share adds a compelling second revenue stream. However, unit economics depend heavily on sensor hardware costs (not included in software pricing) -- the consolidator or homeowner must absorb sensor cost (~$80-200/unit). If AirScore must subsidize sensors to win pilots, margins compress significantly. Also, Year 1 revenue is likely modest ($18K-360K) given enterprise sales cycle realities.

---

## Regulatory & Compliance

### Sensor Certifications Required
| Certification | Requirement | Cost/Timeline |
|--------------|------------|--------------|
| **FCC Part 15** | Required for any BLE/WiFi/RF-emitting device in the US | $5K-15K, 6-12 weeks (via TCB) |
| **UL Listing** | Required if device plugs into AC power; optional for battery-powered | $10K-30K, 3-6 months |
| **CE Marking** | Required for EU market (future expansion) | $5K-10K |

**Note**: If partnering with existing FCC-certified sensor OEMs (Phoenix Sensors, Monnit), AirScore does NOT need its own FCC certification. The sensor partner handles hardware compliance.

### Data Privacy Requirements
- **SOC 2 Type II**: Expected by PE-backed enterprise customers. Covers security, availability, processing integrity, confidentiality, and privacy. Cost: $20K-100K for initial audit, $10K-50K annual renewal.
- **Residential data**: Sensor data (pressure, temperature) is not PII, but location data and home identification are. Need homeowner consent/opt-in mechanism.
- **State privacy laws**: CCPA (California), VCDPA (Virginia), CPA (Colorado) apply if collecting data from homes in those states. Need privacy policy, data deletion rights.
- **HVAC industry**: No specific IoT sensor regulations for residential HVAC installation beyond standard electrical/building codes.

---

## Risk Summary (Updated with Research)
| Risk | Likelihood | Impact | Mitigation | Research Finding |
|------|-----------|--------|------------|-----------------|
| IoT sensor hardware delays | High | High | Partner with existing OEMs (Phoenix, Sensirion), do NOT build hardware | Sensors exist but cost $25-80/unit at volume; FCC cert needed if custom |
| PE consolidator sales cycle (6-18 months) | High | High | Target warm intros via PE operating partners; offer free 50-home pilot | Top 6 consolidators have $1B+ backing; they can pay, but move slowly |
| ServiceTitan competitive response | Medium | Medium | Position as complement, not competitor; build ServiceTitan integration | ServiceTitan has $9B market cap, $772M revenue, but ZERO IoT capability |
| Resideo Pro-IQ competition | Medium | Medium | Differentiate on cross-brand support and PE portfolio analytics | Pro-IQ is Honeywell-locked; no cross-brand, no PE reporting |
| BLE/WiFi reliability in HVAC closets | Medium | Medium | WiFi preferred for single-family; dedicated gateways, not phone-as-gateway | BLE range 10-100m but degrades with metal/obstructions; iOS background BLE is unreliable |
| iOS Core Bluetooth background limitations | High | Medium | Do NOT use iOS app as BLE gateway; use dedicated WiFi/cellular gateway | iOS 26 introduced regressions; background scanning is "opportunistic" |
| Data privacy (residential sensor data) | Medium | High | SOC 2 Type II compliance; homeowner opt-in; anonymize fleet data | SOC 2 costs $20K-100K; sensor data (pressure) is not PII but home location is |
| Sensor cost subsidy pressure | Medium | High | Push sensor cost to consolidator (capex); offer ROI calculator showing payback | Sensor BOM ~$25-80; installed cost ~$100-200; ROI positive if reducing 1 truck roll/year |
| Cold start / chicken-and-egg | High | High | Launch with simulated data; partner with 1 consolidator for proof of concept | No existing cross-brand HVAC IoT fleet platform exists; first-mover advantage but also first-mover risk |
| App Store distribution mismatch | Medium | Medium | B2B SaaS is better distributed via web app + enterprise MDM, not App Store consumer discovery | B2B apps rarely succeed through App Store organic discovery; need direct sales |

---

## Time Estimate (Updated)
- **Build phase (software MVP)**: 60-80 hours
  - iOS dashboard app with simulated sensor data: 30-40 hours
  - Cloud API + data pipeline (mock): 15-20 hours
  - Predictive model (pressure-based filter life): 10-15 hours
  - ServiceTitan integration stub: 5 hours
- **Total pipeline**: 25-35 days
- **Complexity tier**: High
- **Hardware pilot (if pursuing)**: Additional 3-6 months for sensor partner selection, FCC cert, manufacturing

---

## MVP Scope (Unchanged)
- **Must-have features** (v1.0):
  1. Fleet health dashboard (map view of all instrumented homes, color-coded by health status)
  2. Individual home detail view (static pressure trend, filter life remaining, MERV efficiency score)
  3. Dispatch queue (prioritized list of homes needing proactive service, sorted by urgency)
  4. Revenue analytics (filter subscription revenue per location, service call revenue forecast)
  5. Alert management (push notifications for critical equipment events)
  6. StoreKit 2 subscription paywall (or enterprise licensing via API key)
- **Nice-to-have features** (v1.1+):
  1. Technician mobile companion app (job assignment, sensor installation wizard)
  2. Integration with ServiceTitan/Housecall Pro for dispatch handoff
  3. Predictive compressor failure scoring (ML model)
  4. PE investor reporting dashboard (portfolio-level KPIs, EBITDA impact)

## App Store Strategy
- **Category**: Business (primary), Utilities (secondary)
- **Keywords**: HVAC, fleet management, IoT, predictive maintenance, dispatch, filter, air quality, sensor, service, B2B
- **Positioning**: "IoT-Powered HVAC Fleet Intelligence for Enterprise Operators"
- **Distribution concern**: B2B enterprise apps are poorly served by App Store discovery. Consider web app as primary distribution channel, iOS app as companion for field managers.

---

## Overall Research Score: 7/10

**Strengths**:
- Massive, growing market ($350B+ HVAC, 13.6% CAGR in smart/IoT segment)
- Clear gap in competitive landscape (no cross-brand IoT fleet platform for PE consolidators)
- PE consolidators are flush with capital and actively seeking tech differentiation
- Sensor technology exists and is affordable at scale ($25-80/unit)
- Predictive maintenance ROI is well-documented (70% fewer breakdowns, 25% cost reduction)
- Filter subscription revenue model validated by Second Nature ($36.2M raised, 100K+ subscribers)

**Weaknesses**:
- Hardware dependency creates chicken-and-egg problem for software-only MVP
- Enterprise B2B sales cycle (6-18 months) is long for a startup
- iOS-only distribution is a mismatch for B2B enterprise (should be web-first)
- iOS Core Bluetooth background limitations make "phone as gateway" unviable
- Sensor FCC certification adds cost and time if building custom hardware
- SOC 2 compliance required by enterprise customers adds $20K-100K upfront

**Build recommendation**: Proceed with software MVP using simulated sensor data. The platform design, UX, and analytics capabilities can be demonstrated without live sensors. Simultaneously pursue 1-2 warm introductions to PE consolidator operations teams for pilot discussions. If a pilot partner commits, then invest in sensor hardware partnership. If no pilot interest after 90 days, pivot to a lighter SaaS tool (e.g., filter subscription management without IoT).
