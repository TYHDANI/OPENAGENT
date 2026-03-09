import Foundation
import Observation
import CoreLocation

@Observable
final class DataOrchestrator {
    // Data stores
    var earthquakes: [EarthquakePin] = []
    var fires: [FIRMSFire] = []
    var satellites: [SatellitePosition] = []
    var weatherPins: [WeatherPin] = []
    var flights: [FlightPin] = []
    var newsArticles: [NewsArticle] = []
    var iptvChannels: [IPTVChannel] = []
    var iptvStreams: [IPTVStream] = []
    var webcams: [Webcam] = []
    var maxarEvents: [MaxarEvent] = []
    var radarFrames: [RainViewerFrame] = []
    var radarHost: String = ""
    var alerts: [BreakingAlert] = []
    var worldBrief: WorldBrief?

    // Capital Flow stores
    var houseTrades: [CongressTrade] = []
    var senateTrades: [CongressTrade] = []
    var recentContracts: [USASpendingResult] = []
    var lobbyingFilings: [LobbyingFiling] = []
    var sectorSignals: [SectorSignal] = []
    var nationalDebt: Double = 0
    var jobOpenings: [(String, Double)] = []

    // Services
    let weatherService = WeatherService()
    let earthquakeService = EarthquakeService()
    let satelliteService = SatelliteService()
    let fireService = FireService()
    let flightService = FlightService()
    let newsService = NewsService()
    let iptvService = IPTVService()
    let radarService = RadarService()
    let maxarService = MaxarService()
    let capitalFlowService = CapitalFlowService()

    // State
    var isLoading = false
    var lastRefresh: Date?
    var errors: [String] = []
    var activeFeedCount: Int { feedStatuses.filter { $0.value }.count }

    private var feedStatuses: [String: Bool] = [:]
    private var refreshTasks: [Task<Void, Never>] = []

    func startAllFeeds() async {
        isLoading = true
        errors = []

        // Launch all feeds concurrently
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.refreshEarthquakes() }
            group.addTask { await self.refreshFires() }
            group.addTask { await self.refreshSatellites() }
            group.addTask { await self.refreshFlights() }
            group.addTask { await self.refreshNews() }
            group.addTask { await self.refreshIPTV() }
            group.addTask { await self.refreshRadar() }
            group.addTask { await self.refreshMaxar() }
            group.addTask { await self.refreshWeatherGrid() }
            group.addTask { await self.refreshCapitalFlows() }
        }

        generateAlerts()
        generateWorldBrief()
        generateSectorSignals()

        isLoading = false
        lastRefresh = .now
    }

    // MARK: - Individual Feed Refreshers

    func refreshEarthquakes() async {
        do {
            let data = try await earthquakeService.fetchSignificant()
            await MainActor.run { self.earthquakes = data }
            feedStatuses["earthquakes"] = true
        } catch {
            feedStatuses["earthquakes"] = false
            errors.append("Earthquakes: \(error.localizedDescription)")
        }
    }

    func refreshFires() async {
        do {
            let data = try await fireService.fetchActiveFires()
            await MainActor.run { self.fires = data }
            feedStatuses["fires"] = true
        } catch {
            feedStatuses["fires"] = false
            errors.append("Fires: \(error.localizedDescription)")
        }
    }

    func refreshSatellites() async {
        do {
            let data = try await satelliteService.fetchAndPropagate(groups: [.stations, .starlink, .visual])
            await MainActor.run { self.satellites = data }
            feedStatuses["satellites"] = true
        } catch {
            feedStatuses["satellites"] = false
            errors.append("Satellites: \(error.localizedDescription)")
        }
    }

    func refreshFlights() async {
        do {
            let data = try await flightService.fetchAll()
            await MainActor.run { self.flights = data }
            feedStatuses["flights"] = true
        } catch {
            feedStatuses["flights"] = false
            errors.append("Flights: \(error.localizedDescription)")
        }
    }

    func refreshNews() async {
        do {
            let data = try await newsService.fetchAllFeeds()
            await MainActor.run { self.newsArticles = data }
            feedStatuses["news"] = true
        } catch {
            feedStatuses["news"] = false
            errors.append("News: \(error.localizedDescription)")
        }
    }

    func refreshIPTV() async {
        do {
            let (channels, streams) = try await iptvService.fetchChannelsAndStreams()
            await MainActor.run {
                self.iptvChannels = channels
                self.iptvStreams = streams
            }
            feedStatuses["iptv"] = true
        } catch {
            feedStatuses["iptv"] = false
            errors.append("IPTV: \(error.localizedDescription)")
        }
    }

    func refreshRadar() async {
        do {
            let (host, frames) = try await radarService.fetchRadarFrames()
            await MainActor.run {
                self.radarHost = host
                self.radarFrames = frames
            }
            feedStatuses["radar"] = true
        } catch {
            feedStatuses["radar"] = false
            errors.append("Radar: \(error.localizedDescription)")
        }
    }

    func refreshMaxar() async {
        do {
            let data = try await maxarService.fetchEvents()
            await MainActor.run { self.maxarEvents = data }
            feedStatuses["maxar"] = true
        } catch {
            feedStatuses["maxar"] = false
            errors.append("Maxar: \(error.localizedDescription)")
        }
    }

    func refreshWeatherGrid() async {
        let majorCities: [(String, Double, Double)] = [
            ("New York", 40.71, -74.01), ("London", 51.51, -0.13), ("Tokyo", 35.68, 139.69),
            ("Paris", 48.86, 2.35), ("Dubai", 25.20, 55.27), ("Sydney", -33.87, 151.21),
            ("Moscow", 55.76, 37.62), ("Beijing", 39.90, 116.40), ("Mumbai", 19.08, 72.88),
            ("Cairo", 30.04, 31.24), ("São Paulo", -23.55, -46.63), ("Lagos", 6.52, 3.38),
            ("Singapore", 1.35, 103.82), ("Berlin", 52.52, 13.41), ("Seoul", 37.57, 126.98),
            ("Mexico City", 19.43, -99.13), ("Istanbul", 41.01, 28.98), ("Bangkok", 13.76, 100.50),
            ("Nairobi", -1.29, 36.82), ("Lima", -12.05, -77.04),
        ]

        await withTaskGroup(of: WeatherPin?.self) { group in
            for (city, lat, lon) in majorCities {
                group.addTask {
                    try? await self.weatherService.fetchCurrentWeather(lat: lat, lon: lon, city: city)
                }
            }
            var pins: [WeatherPin] = []
            for await pin in group {
                if let pin { pins.append(pin) }
            }
            await MainActor.run { self.weatherPins = pins }
        }
        feedStatuses["weather"] = true
    }

    // MARK: - Capital Flow Feeds

    func refreshCapitalFlows() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.refreshHouseTrades() }
            group.addTask { await self.refreshSenateTrades() }
            group.addTask { await self.refreshContracts() }
            group.addTask { await self.refreshLobbying() }
            group.addTask { await self.refreshDebt() }
            group.addTask { await self.refreshJobs() }
        }
        generateSectorSignals()
    }

    private func refreshHouseTrades() async {
        do {
            let data = try await capitalFlowService.fetchHouseTrades()
            await MainActor.run { self.houseTrades = data }
            feedStatuses["houseTrades"] = true
        } catch {
            feedStatuses["houseTrades"] = false
            errors.append("House Trades: \(error.localizedDescription)")
        }
    }

    private func refreshSenateTrades() async {
        do {
            let data = try await capitalFlowService.fetchSenateTrades()
            await MainActor.run { self.senateTrades = data }
            feedStatuses["senateTrades"] = true
        } catch {
            feedStatuses["senateTrades"] = false
            errors.append("Senate Trades: \(error.localizedDescription)")
        }
    }

    private func refreshContracts() async {
        do {
            let data = try await capitalFlowService.fetchRecentContracts()
            await MainActor.run { self.recentContracts = data }
            feedStatuses["contracts"] = true
        } catch {
            feedStatuses["contracts"] = false
            errors.append("Contracts: \(error.localizedDescription)")
        }
    }

    private func refreshLobbying() async {
        do {
            let data = try await capitalFlowService.fetchRecentLobbying()
            await MainActor.run { self.lobbyingFilings = data }
            feedStatuses["lobbying"] = true
        } catch {
            feedStatuses["lobbying"] = false
            errors.append("Lobbying: \(error.localizedDescription)")
        }
    }

    private func refreshDebt() async {
        do {
            let debt = try await capitalFlowService.fetchNationalDebt()
            await MainActor.run { self.nationalDebt = debt }
        } catch {
            errors.append("Treasury: \(error.localizedDescription)")
        }
    }

    private func refreshJobs() async {
        do {
            let jobs = try await capitalFlowService.fetchJobOpenings()
            await MainActor.run { self.jobOpenings = jobs }
        } catch {
            errors.append("BLS Jobs: \(error.localizedDescription)")
        }
    }

    // MARK: - Sector Signal Generation
    private func generateSectorSignals() {
        // analyzeSectorSignals is synchronous logic — run with local copies
        let h = houseTrades
        let s = senateTrades
        let c = recentContracts
        Task {
            let signals = await capitalFlowService.analyzeSectorSignals(
                houseTrades: h,
                senateTrades: s,
                contracts: c
            )
            await MainActor.run { self.sectorSignals = signals }
        }
    }

    // MARK: - Alert Generation
    private func generateAlerts() {
        var newAlerts: [BreakingAlert] = []

        // Major earthquakes
        for eq in earthquakes where eq.magnitude >= 5.0 {
            newAlerts.append(BreakingAlert(
                title: "M\(String(format: "%.1f", eq.magnitude)) Earthquake",
                description: eq.place,
                category: .naturalDisaster,
                severity: eq.magnitude >= 7 ? .severe : eq.magnitude >= 6 ? .high : .elevated,
                coordinate: eq.coordinate,
                timestamp: eq.time,
                source: "USGS",
                isRead: false
            ))
        }

        // High-confidence fires in clusters
        let highFires = fires.filter { $0.isHighConfidence }
        if highFires.count > 50 {
            newAlerts.append(BreakingAlert(
                title: "\(highFires.count) Active Wildfires Detected",
                description: "NASA FIRMS reports elevated fire activity globally",
                category: .naturalDisaster,
                severity: .elevated,
                coordinate: highFires.first?.coordinate,
                timestamp: .now,
                source: "NASA FIRMS",
                isRead: false
            ))
        }

        alerts = newAlerts.sorted { $0.timestamp > $1.timestamp }
    }

    // MARK: - World Brief Generation
    private func generateWorldBrief() {
        var events: [BriefEvent] = []

        // Top earthquakes
        for eq in earthquakes.prefix(3) where eq.magnitude >= 4.0 {
            events.append(BriefEvent(
                headline: "M\(String(format: "%.1f", eq.magnitude)) earthquake near \(eq.place)",
                description: "Depth: \(String(format: "%.1f", eq.depth))km. \(eq.tsunami ? "Tsunami warning issued." : "No tsunami expected.")",
                region: eq.place,
                category: .naturalDisaster,
                severity: eq.magnitude >= 6 ? .high : .elevated,
                coordinate: eq.coordinate,
                sources: ["USGS"],
                timestamp: eq.time
            ))
        }

        // Active fires summary
        if !fires.isEmpty {
            events.append(BriefEvent(
                headline: "\(fires.count) active fires detected globally",
                description: "\(fires.filter { $0.isHighConfidence }.count) high-confidence detections via satellite sensors",
                region: "Global",
                category: .naturalDisaster,
                severity: fires.count > 100 ? .elevated : .guarded,
                coordinate: nil,
                sources: ["NASA FIRMS"],
                timestamp: .now
            ))
        }

        // Flight activity
        if !flights.isEmpty {
            let militaryCount = flights.filter { $0.isMilitary }.count
            if militaryCount > 0 {
                events.append(BriefEvent(
                    headline: "\(militaryCount) military aircraft tracked",
                    description: "\(flights.count) total aircraft in monitored airspace",
                    region: "Global",
                    category: .aviation,
                    severity: .guarded,
                    coordinate: nil,
                    sources: ["OpenSky Network"],
                    timestamp: .now
                ))
            }
        }

        // Top news
        for article in newsArticles.prefix(2) {
            events.append(BriefEvent(
                headline: article.title,
                description: article.description ?? "",
                region: article.source,
                category: .political,
                severity: .guarded,
                coordinate: article.coordinate,
                sources: [article.source],
                timestamp: article.pubDate ?? .now
            ))
        }

        let threatLevel: ThreatLevel = {
            if earthquakes.contains(where: { $0.magnitude >= 7.0 }) { return .severe }
            if earthquakes.contains(where: { $0.magnitude >= 6.0 }) { return .high }
            if fires.count > 200 { return .elevated }
            return .guarded
        }()

        worldBrief = WorldBrief(
            title: "Global Intelligence Brief",
            summary: "Monitoring \(earthquakes.count) seismic events, \(fires.count) active fires, \(satellites.count) satellites, \(flights.count) aircraft, and \(newsArticles.count) news sources.",
            events: events,
            generatedAt: .now,
            globalThreatLevel: threatLevel
        )
    }
}
