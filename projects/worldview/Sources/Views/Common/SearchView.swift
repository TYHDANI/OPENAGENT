import SwiftUI

struct SearchView: View {
    @Binding var searchText: String
    @Binding var results: [GeocodingResult]
    let onSelect: (GeocodingResult) -> Void
    @State private var isSearching = false
    private let weatherService = WeatherService()

    var body: some View {
        NavigationStack {
            ZStack {
                NETheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search field
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(NETheme.textTertiary)
                        TextField("Search cities, regions...", text: $searchText)
                            .font(NETheme.body())
                            .foregroundStyle(NETheme.textPrimary)
                            .autocorrectionDisabled()
                            .onSubmit { search() }
                        if isSearching {
                            ProgressView().tint(NETheme.accent).scaleEffect(0.8)
                        }
                        if !searchText.isEmpty {
                            Button { searchText = ""; results = [] } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(NETheme.textTertiary)
                            }
                        }
                    }
                    .padding(12)
                    .background(NETheme.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()

                    // Results
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(results) { result in
                                Button {
                                    onSelect(result)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundStyle(NETheme.accent)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(result.name)
                                                .font(NETheme.subheading(15))
                                                .foregroundStyle(NETheme.textPrimary)
                                            HStack(spacing: 6) {
                                                if let admin = result.admin1 {
                                                    Text(admin)
                                                }
                                                if let country = result.country {
                                                    Text(country)
                                                }
                                            }
                                            .font(NETheme.caption())
                                            .foregroundStyle(NETheme.textTertiary)
                                        }

                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(String(format: "%.2f, %.2f", result.latitude, result.longitude))
                                                .font(NETheme.mono(10))
                                                .foregroundStyle(NETheme.textTertiary)
                                            if let elev = result.elevation {
                                                Text("\(Int(elev))m")
                                                    .font(NETheme.mono(10))
                                                    .foregroundStyle(NETheme.textTertiary)
                                            }
                                        }
                                    }
                                    .padding(12)
                                    .glassCard(cornerRadius: 12)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: searchText) { _, newValue in
            guard newValue.count >= 2 else { results = []; return }
            search()
        }
    }

    private func search() {
        guard !searchText.isEmpty else { return }
        isSearching = true
        Task {
            do {
                let r = try await weatherService.searchCity(searchText)
                await MainActor.run {
                    results = r
                    isSearching = false
                }
            } catch {
                await MainActor.run { isSearching = false }
            }
        }
    }
}

// MARK: - Detail Sheet
struct DetailSheet: View {
    let item: SelectedMapItem
    @Environment(DataOrchestrator.self) private var data

    var body: some View {
        NavigationStack {
            ZStack {
                NETheme.background.ignoresSafeArea()

                ScrollView {
                    switch item {
                    case .earthquake(let id):
                        if let eq = data.earthquakes.first(where: { $0.id == id }) {
                            EarthquakeDetailView(earthquake: eq)
                        }
                    case .weather(let id):
                        if let pin = data.weatherPins.first(where: { $0.id.uuidString == id }) {
                            WeatherDetailView(pin: pin)
                        }
                    case .satellite(let id):
                        if let sat = data.satellites.first(where: { $0.id == id }) {
                            SatelliteDetailView(satellite: sat)
                        }
                    default:
                        Text("Details")
                            .foregroundStyle(NETheme.textPrimary)
                    }
                }
            }
        }
    }
}

// MARK: - Earthquake Detail
struct EarthquakeDetailView: View {
    let earthquake: EarthquakePin

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                MagnitudeIndicator(magnitude: earthquake.magnitude)
                VStack(alignment: .leading) {
                    Text("Magnitude \(String(format: "%.1f", earthquake.magnitude))")
                        .font(NETheme.heading(20))
                        .foregroundStyle(NETheme.textPrimary)
                    Text(earthquake.place)
                        .font(NETheme.body())
                        .foregroundStyle(NETheme.textSecondary)
                }
            }

            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                GridRow {
                    Label("Depth", systemImage: "arrow.down.to.line")
                    Text(String(format: "%.1f km", earthquake.depth))
                }
                GridRow {
                    Label("Time", systemImage: "clock")
                    Text(earthquake.time.formatted())
                }
                GridRow {
                    Label("Tsunami", systemImage: "water.waves")
                    Text(earthquake.tsunami ? "Warning Issued" : "No Warning")
                        .foregroundStyle(earthquake.tsunami ? NETheme.severityCritical : NETheme.severityLow)
                }
                GridRow {
                    Label("Coordinates", systemImage: "mappin")
                    Text(String(format: "%.4f, %.4f", earthquake.coordinate.latitude, earthquake.coordinate.longitude))
                        .font(NETheme.mono(12))
                }
            }
            .font(NETheme.body())
            .foregroundStyle(NETheme.textSecondary)
        }
        .padding()
    }
}

// MARK: - Weather Detail
struct WeatherDetailView: View {
    let pin: WeatherPin

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: WeatherCondition.from(code: pin.weatherCode).icon)
                    .font(.system(size: 40))
                    .foregroundStyle(NETheme.weatherColor)
                VStack(alignment: .leading) {
                    Text(pin.city)
                        .font(NETheme.heading(20))
                        .foregroundStyle(NETheme.textPrimary)
                    Text(WeatherCondition.from(code: pin.weatherCode).description)
                        .font(NETheme.body())
                        .foregroundStyle(NETheme.textSecondary)
                }
                Spacer()
                Text("\(Int(pin.temperature))\u{00B0}")
                    .font(.system(size: 44, weight: .thin, design: .default))
                    .foregroundStyle(NETheme.textPrimary)
            }

            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                if let humidity = pin.humidity {
                    GridRow {
                        Label("Humidity", systemImage: "humidity")
                        Text("\(humidity)%")
                    }
                }
                if let wind = pin.windSpeed {
                    GridRow {
                        Label("Wind", systemImage: "wind")
                        Text(String(format: "%.1f km/h", wind))
                    }
                }
            }
            .font(NETheme.body())
            .foregroundStyle(NETheme.textSecondary)
        }
        .padding()
    }
}

// MARK: - Satellite Detail
struct SatelliteDetailView: View {
    let satellite: SatellitePosition

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: satellite.group.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(Color(hex: satellite.group.color))
                VStack(alignment: .leading) {
                    Text(satellite.name)
                        .font(NETheme.heading(18))
                        .foregroundStyle(NETheme.textPrimary)
                    Text("NORAD ID: \(satellite.id)")
                        .font(NETheme.mono(12))
                        .foregroundStyle(NETheme.textTertiary)
                }
            }

            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                GridRow {
                    Label("Altitude", systemImage: "arrow.up.to.line")
                    Text(satellite.altitudeFormatted)
                }
                GridRow {
                    Label("Velocity", systemImage: "speedometer")
                    Text(String(format: "%.2f km/s", satellite.velocity))
                }
                GridRow {
                    Label("Position", systemImage: "mappin")
                    Text(String(format: "%.4f, %.4f", satellite.coordinate.latitude, satellite.coordinate.longitude))
                        .font(NETheme.mono(12))
                }
                GridRow {
                    Label("Group", systemImage: "tag")
                    Text(satellite.group.displayName)
                }
            }
            .font(NETheme.body())
            .foregroundStyle(NETheme.textSecondary)
        }
        .padding()
    }
}
