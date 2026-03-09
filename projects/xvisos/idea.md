# XvisOS — Infrared & Night Vision Camera App

## Core Concept
An iOS camera app that transforms the iPhone camera into an infrared/night vision viewer using real-time image processing and Core Image filters. Users can see in low-light conditions using enhanced thermal-style and night-vision-style overlays.

## Features
- **Night Vision Mode**: Green-tinted amplified light view (classic NVG look)
- **Thermal Vision Mode**: False-color heat map overlay using camera contrast data
- **Infrared Simulation**: Near-IR look using color channel manipulation
- **Predator Vision Mode**: Sci-fi thermal predator-style overlay
- **Photo & Video Capture**: Save enhanced footage
- **Real-time Processing**: 30fps minimum using Metal/Core Image GPU pipeline
- **Zoom & Focus**: Digital zoom with enhanced low-light processing
- **Comparison Mode**: Split screen showing normal vs enhanced view

## Technical Approach
- Core Image + Metal shaders for real-time filter processing
- AVFoundation for camera access with RAW sensor data (where available)
- Histogram equalization for low-light enhancement
- Color lookup tables (CLUTs) for thermal/IR false coloring
- iPhone LIDAR sensor integration (Pro models) for depth-based thermal simulation

## Monetization
- Freemium: Night Vision mode free, Thermal/IR/Predator modes behind paywall
- .99/month or .99/year subscription
- One-time unlock option: .99

## Target Market
- Outdoor enthusiasts (camping, hiking, hunting)
- Security/surveillance hobbyists
- Photography enthusiasts
- Paranormal investigation community
- Military/tactical enthusiasts

## Revenue Potential
- App Store camera/photo category has high demand
- Night vision hardware costs -2000+ — app is a fraction of the price
- Similar apps (Night Vision Camera, Thermal Camera+) generate K-20K/month
- With good marketing: K-30K/month realistic within 6 months
