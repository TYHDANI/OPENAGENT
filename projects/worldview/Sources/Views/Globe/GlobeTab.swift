import SwiftUI
import MapKit

struct GlobeTab: View {
    @Environment(AppState.self) private var appState
    @Environment(DataOrchestrator.self) private var data
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedItem: SelectedMapItem?
    @State private var showSearch = false
    @State private var searchResults: [GeocodingResult] = []
    @State private var searchText = ""

    var body: some View {
        @Bindable var state = appState

        ZStack {
            // MARK: - 3D Globe Map
            Map(position: $cameraPosition, selection: $selectedItem) {
                // Earthquakes
                if state.activeDataLayers.contains(.earthquakes) {
                    ForEach(data.earthquakes) { eq in
                        Annotation(eq.place, coordinate: eq.coordinate) {
                            EarthquakeAnnotation(earthquake: eq)
                        }
                        .tag(SelectedMapItem.earthquake(eq.id))
                    }
                }

                // Wildfires
                if state.activeDataLayers.contains(.wildfires) {
                    ForEach(data.fires) { fire in
                        Annotation("", coordinate: fire.coordinate) {
                            FireAnnotation(fire: fire)
                        }
                    }
                }

                // Weather
                if state.activeDataLayers.contains(.weather) {
                    ForEach(data.weatherPins) { pin in
                        Annotation(pin.city, coordinate: pin.coordinate) {
                            WeatherAnnotation(pin: pin)
                        }
                        .tag(SelectedMapItem.weather(pin.id.uuidString))
                    }
                }

                // Satellites (ISS & visible)
                if state.activeDataLayers.contains(.satellites) {
                    ForEach(data.satellites.filter { $0.group == .stations || $0.group == .visual }.prefix(100), id: \.id) { sat in
                        Annotation(sat.name, coordinate: sat.coordinate) {
                            SatelliteAnnotation(satellite: sat)
                        }
                        .tag(SelectedMapItem.satellite(sat.id))
                    }
                }

                // Flights
                if state.activeDataLayers.contains(.militaryFlights) {
                    ForEach(data.flights.filter { $0.isMilitary }.prefix(200), id: \.id) { flight in
                        Annotation(flight.callsign ?? flight.id, coordinate: flight.coordinate) {
                            FlightAnnotation(flight: flight)
                        }
                    }
                }

                // Maxar Satellite Imagery Events
                if state.activeDataLayers.contains(.maxarImagery) {
                    ForEach(data.maxarEvents.filter { $0.coordinate != nil }) { event in
                        if let coord = event.coordinate {
                            Annotation(event.title, coordinate: coord) {
                                MaxarAnnotation(event: event)
                            }
                        }
                    }
                }
            }
            .mapStyle(.imagery(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapScaleView()
                MapPitchToggle()
            }

            // MARK: - Overlay Controls
            VStack {
                // Top Bar
                HStack {
                    // Region Selector
                    Menu {
                        ForEach(RegionPreset.allCases) { region in
                            Button(region.rawValue) {
                                withAnimation(.easeInOut(duration: 0.8)) {
                                    state.selectedRegion = region
                                    cameraPosition = .region(MKCoordinateRegion(
                                        center: region.center,
                                        span: region.span
                                    ))
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "globe")
                            Text(state.selectedRegion.rawValue)
                                .font(NETheme.subheading(13))
                        }
                        .foregroundStyle(NETheme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .glassCard(cornerRadius: 20)
                    }

                    Spacer()

                    // Feed Status Bar
                    HStack(spacing: 4) {
                        DataFreshnessPill(lastUpdate: data.lastRefresh)
                        if data.isLoading {
                            ProgressView()
                                .tint(NETheme.accent)
                                .scaleEffect(0.7)
                        }
                    }

                    // Search
                    Button {
                        showSearch.toggle()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundStyle(NETheme.accent)
                            .frame(width: 36, height: 36)
                            .glassCard(cornerRadius: 18)
                    }

                    // Layer Panel
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            state.showLayerPanel.toggle()
                        }
                    } label: {
                        Image(systemName: "square.3.layers.3d")
                            .font(.system(size: 16))
                            .foregroundStyle(NETheme.accent)
                            .frame(width: 36, height: 36)
                            .glassCard(cornerRadius: 18)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                // MARK: - Bottom Feed Tickers
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FeedStatusIndicator(name: "Quakes", count: data.earthquakes.count, color: NETheme.earthquakeColor, icon: "waveform.path.ecg")
                        FeedStatusIndicator(name: "Fires", count: data.fires.count, color: NETheme.fireColor, icon: "flame")
                        FeedStatusIndicator(name: "Sats", count: data.satellites.count, color: NETheme.satelliteColor, icon: "satellite")
                        FeedStatusIndicator(name: "Flights", count: data.flights.count, color: NETheme.flightColor, icon: "airplane")
                        FeedStatusIndicator(name: "News", count: data.newsArticles.count, color: NETheme.newsColor, icon: "newspaper")
                        FeedStatusIndicator(name: "Channels", count: data.iptvChannels.count, color: NETheme.marineColor, icon: "play.tv")
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 4)

                // Timeline Scrubber
                TimelineScrubber()
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

            // MARK: - Layer Panel Sheet
            if state.showLayerPanel {
                LayerPanelView()
                    .transition(.move(edge: .trailing))
            }
        }
        .sheet(isPresented: $showSearch) {
            SearchView(searchText: $searchText, results: $searchResults) { result in
                cameraPosition = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: result.latitude, longitude: result.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
                ))
                showSearch = false
            }
        }
        .sheet(item: $selectedItem) { item in
            DetailSheet(item: item)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Selected Map Item
enum SelectedMapItem: Identifiable, Hashable {
    case earthquake(String)
    case weather(String)
    case satellite(Int)
    case flight(String)
    case maxar(String)

    var id: String {
        switch self {
        case .earthquake(let id): return "eq-\(id)"
        case .weather(let id): return "wx-\(id)"
        case .satellite(let id): return "sat-\(id)"
        case .flight(let id): return "fl-\(id)"
        case .maxar(let id): return "mx-\(id)"
        }
    }
}

// MARK: - Map Annotations
struct EarthquakeAnnotation: View {
    let earthquake: EarthquakePin

    var body: some View {
        MagnitudeIndicator(magnitude: earthquake.magnitude)
            .accessibilityLabel("Magnitude \(String(format: "%.1f", earthquake.magnitude)) earthquake at \(earthquake.place)")
    }
}

struct FireAnnotation: View {
    let fire: FIRMSFire

    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: fire.isHighConfidence ? 14 : 10))
            .foregroundStyle(fire.isHighConfidence ? NETheme.fireColor : .orange.opacity(0.7))
            .shadow(color: NETheme.fireColor.opacity(0.5), radius: 4)
    }
}

struct WeatherAnnotation: View {
    let pin: WeatherPin

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: WeatherCondition.from(code: pin.weatherCode).icon)
                .font(.system(size: 16))
                .foregroundStyle(NETheme.weatherColor)
            Text("\(Int(pin.temperature))\u{00B0}")
                .font(NETheme.mono(11))
                .foregroundStyle(.white)
        }
        .padding(6)
        .glassCard(cornerRadius: 8)
    }
}

struct SatelliteAnnotation: View {
    let satellite: SatellitePosition

    var body: some View {
        Image(systemName: satellite.group == .stations ? "globe.americas.fill" : "satellite.fill")
            .font(.system(size: satellite.group == .stations ? 16 : 8))
            .foregroundStyle(Color(hex: satellite.group.color))
            .shadow(color: Color(hex: satellite.group.color).opacity(0.6), radius: 4)
    }
}

struct FlightAnnotation: View {
    let flight: FlightPin

    var body: some View {
        Image(systemName: "airplane")
            .font(.system(size: 12))
            .foregroundStyle(flight.isMilitary ? NETheme.severityCritical : NETheme.flightColor)
            .rotationEffect(.degrees(flight.heading))
    }
}

struct MaxarAnnotation: View {
    let event: MaxarEvent

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: event.icon)
                .font(.system(size: 14))
                .foregroundStyle(.white)
            Text("SAT")
                .font(NETheme.mono(8))
                .foregroundStyle(NETheme.accent)
        }
        .padding(6)
        .background(NETheme.surfaceElevated.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(NETheme.accent.opacity(0.5), lineWidth: 1)
        )
    }
}
