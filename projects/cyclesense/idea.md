# CycleSense — AI Macro Intelligence & Economic Cycle Tracker

## Problem
Ray Dalio proved that economic cycles repeat every ~80 years across 5 forces, but no consumer tool tracks these forces in real-time. Retail investors ($5.6B finance app market) make decisions without understanding where we are in the macro cycle — leading to buying at peaks and selling at bottoms.

## Solution
Ray Dalio's "Principles for Dealing with the Changing World Order" as a real-time intelligence app.
- **5-Force Dashboard**: Track all of Dalio's macro forces with live data:
  1. Debt/GDP ratios for 20 major economies (Fed, ECB, BOJ data)
  2. Internal conflict indices (wealth gap metrics, political polarization scores, protest frequency)
  3. Geopolitical tension heatmap (military movements, sanctions, trade volume changes)
  4. Natural disaster frequency/severity trends (NOAA, USGS data)
  5. Technology race scoreboard (AI patents by country, semiconductor output, R&D spend, talent migration)
- **Cycle Position Indicator**: AI-generated weekly report answering "Where are we in the 80-year cycle?" with historical overlays (current vs 1930s, 1970s, 2000s, Roman Empire decline)
- **Portfolio Implications**: Based on cycle position, suggest asset allocation shifts (bonds vs equities vs commodities vs cash vs crypto)
- **Country Risk Scoring**: Per-country composite risk score across all 5 forces (answering Dalio's "should I be in the UK or US?")
- **Empire Health Index**: Track the rise/decline of major powers (US, China, EU, India) using Dalio's 18 determinants of power
- **Breaking Cycle Alerts**: Push notifications when a force crosses a critical threshold (e.g., debt/GDP > 120%, political polarization index > 80th percentile)

## Target Audience
Retail investors, macro traders, financial advisors, economics students, geopolitics enthusiasts. People who read Ray Dalio, follow macro Twitter, trade based on economic cycles. 100M+ retail investors globally.

## Monetization
Freemium with subscription:
- Free: Monthly cycle overview, basic 5-force scores, 2 countries
- Analyst ($14.99/mo or $119.99/yr): Weekly reports, all 5 forces detailed, 20 countries, historical overlays, portfolio suggestions
- Pro ($39.99/mo or $299.99/yr): Daily updates, custom alerts, API access, country comparisons, empire health index, export data
- Enterprise ($199.99/mo): Team access, custom data integrations, white-label reports

## Competition
- **Bloomberg Terminal** ($24K/yr): Institutional only, no cycle framework
- **Koyfin** ($35/mo): Charts and data, no macro cycle analysis
- **MacroMicro** ($29/mo): Good data but no Dalio framework, no AI synthesis
- **FRED (St. Louis Fed)**: Free data but raw, no framework, no mobile app
- **None** productize Dalio's 5-force framework with real-time data and AI analysis

## Notes
Inspired by Ray Dalio's interview on the 5 big forces and 80-year cycles, combined with his book "Principles for Dealing with the Changing World Order." All data sources are free government APIs (FRED, World Bank, IMF, USGS, NOAA). SwiftUI + Swift Charts for visualizations. On-device caching for offline access. Push notifications for cycle alerts.
