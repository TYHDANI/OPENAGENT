import Foundation
import CoreLocation

actor FireService {
    // NASA FIRMS CSV endpoint — free, no API key for last 24h active fires
    private let firmsURL = "https://firms.modaps.eosdis.nasa.gov/api/area/csv/VALID_KEY/VIIRS_SNPP_NRT/world/1"
    // Fallback: FIRMS open data CSV (24-hour snapshot, publicly cached)
    private let openFiresURL = "https://firms.modaps.eosdis.nasa.gov/data/active_fire/suomi-npp-viirs-c2/csv/SUOMI_VIIRS_C2_Global_24h.csv"
    private let session = URLSession.shared

    func fetchActiveFires() async throws -> [FIRMSFire] {
        // Try the open CSV endpoint first
        let url = URL(string: openFiresURL)!
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        let (data, _) = try await session.data(for: request)

        guard let csvString = String(data: data, encoding: .utf8) else {
            return []
        }

        return parseCSV(csvString)
    }

    private func parseCSV(_ csv: String) -> [FIRMSFire] {
        let lines = csv.components(separatedBy: "\n")
        guard lines.count > 1 else { return [] }

        let header = lines[0].components(separatedBy: ",")
        let latIdx = header.firstIndex(of: "latitude") ?? 0
        let lonIdx = header.firstIndex(of: "longitude") ?? 1
        let brightIdx = header.firstIndex(of: "bright_ti4") ?? header.firstIndex(of: "brightness") ?? 2
        let confIdx = header.firstIndex(of: "confidence") ?? 8
        let frpIdx = header.firstIndex(of: "frp") ?? 12
        let satIdx = header.firstIndex(of: "satellite") ?? 6
        let dateIdx = header.firstIndex(of: "acq_date") ?? 5
        let timeIdx = header.firstIndex(of: "acq_time") ?? 6
        let dnIdx = header.firstIndex(of: "daynight") ?? 9

        var fires: [FIRMSFire] = []
        // Limit to 500 for performance
        for line in lines[1...].prefix(500) {
            let fields = line.components(separatedBy: ",")
            guard fields.count > max(latIdx, lonIdx, brightIdx) else { continue }

            guard let lat = Double(fields[latIdx]),
                  let lon = Double(fields[lonIdx]) else { continue }

            let brightness = Double(fields[safe: brightIdx] ?? "0") ?? 0
            let frp = Double(fields[safe: frpIdx] ?? "0") ?? 0

            fires.append(FIRMSFire(
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                brightness: brightness,
                confidence: fields[safe: confIdx] ?? "nominal",
                frp: frp,
                satellite: fields[safe: satIdx] ?? "VIIRS",
                acquisitionDate: fields[safe: dateIdx] ?? "",
                acquisitionTime: fields[safe: timeIdx] ?? "",
                dayNight: fields[safe: dnIdx] ?? "D"
            ))
        }
        return fires
    }
}

private extension Array where Element == String {
    subscript(safe index: Int) -> String? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
