import Foundation

@Observable
final class AirQualityService {
    var properties: [Property] = []
    var readings: [AirReading] = []
    var alerts: [AlertItem] = []

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() { load() }

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func load() {
        properties = read("properties.json") ?? SampleData.properties
        readings = read("readings.json") ?? SampleData.readings
        alerts = read("alerts.json") ?? []
        updateLatestReadings()
    }

    func save() {
        write(properties, to: "properties.json")
        write(readings, to: "readings.json")
        write(alerts, to: "alerts.json")
    }

    func addReading(_ reading: AirReading) {
        readings.append(reading)
        updateLatestReadings()
        checkAlerts(reading)
        save()
    }

    func overallAQI(fleetOnly: Bool = false) -> Int {
        let props = fleetOnly ? properties.filter { $0.isFleetProperty } : properties
        let aqis = props.map { $0.overallAQI }.filter { $0 > 0 }
        guard !aqis.isEmpty else { return 0 }
        return aqis.reduce(0, +) / aqis.count
    }

    var homeProperties: [Property] { properties.filter { !$0.isFleetProperty } }
    var fleetProperties: [Property] { properties.filter { $0.isFleetProperty } }
    var unreadAlerts: [AlertItem] { alerts.filter { !$0.isRead } }
    var filtersNeedingChange: Int { properties.reduce(0) { $0 + $1.filtersNeedingChange } }

    private func updateLatestReadings() {
        for i in properties.indices {
            for j in properties[i].rooms.indices {
                let roomID = properties[i].rooms[j].id
                properties[i].rooms[j].latestReading = readings
                    .filter { $0.roomID == roomID }
                    .sorted { $0.timestamp > $1.timestamp }
                    .first
            }
        }
    }

    private func checkAlerts(_ reading: AirReading) {
        if reading.aqi > 150 {
            alerts.append(AlertItem(category: .aqiSpike, severity: .critical,
                                    title: "AQI Spike", message: "AQI reached \(reading.aqi)", roomID: reading.roomID))
        }
        if reading.co2 > 1000 {
            alerts.append(AlertItem(category: .co2High, severity: .warning,
                                    title: "High CO2", message: "CO2 at \(Int(reading.co2)) ppm", roomID: reading.roomID))
        }
        if reading.humidity < 30 || reading.humidity > 60 {
            alerts.append(AlertItem(category: .humidityOutOfRange, severity: .info,
                                    title: "Humidity Alert", message: "\(Int(reading.humidity))% humidity", roomID: reading.roomID))
        }
        if reading.voc > 500 {
            alerts.append(AlertItem(category: .vocAlert, severity: .warning,
                                    title: "VOC Alert", message: "VOC at \(Int(reading.voc)) ppb", roomID: reading.roomID))
        }
    }

    private func write<T: Encodable>(_ value: T, to filename: String) {
        let url = documentsURL.appendingPathComponent(filename)
        try? encoder.encode(value).write(to: url)
    }

    private func read<T: Decodable>(_ filename: String) -> T? {
        let url = documentsURL.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }
}
