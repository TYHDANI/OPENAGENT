import Foundation
import CoreLocation

actor EarthquakeService {
    private let baseURL = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary"
    private let session = URLSession.shared

    enum FeedType: String {
        case significantMonth = "significant_month"
        case m45Week = "4.5_week"
        case m25Week = "2.5_week"
        case m1Week = "1.0_week"
        case allDay = "all_day"
        case allHour = "all_hour"
    }

    func fetchSignificant() async throws -> [EarthquakePin] {
        try await fetch(feed: .m25Week)
    }

    func fetch(feed: FeedType = .m25Week) async throws -> [EarthquakePin] {
        let url = URL(string: "\(baseURL)/\(feed.rawValue).geojson")!
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(USGSResponse.self, from: data)

        return response.features.compactMap { feature -> EarthquakePin? in
            let coords = feature.geometry.coordinates
            guard coords.count >= 3,
                  let mag = feature.properties.mag else { return nil }

            return EarthquakePin(
                id: feature.id,
                coordinate: CLLocationCoordinate2D(latitude: coords[1], longitude: coords[0]),
                magnitude: mag,
                depth: coords[2],
                place: feature.properties.place ?? "Unknown",
                time: Date(timeIntervalSince1970: TimeInterval((feature.properties.time ?? 0)) / 1000),
                tsunami: (feature.properties.tsunami ?? 0) == 1,
                alert: feature.properties.alert,
                significance: feature.properties.sig ?? 0
            )
        }.sorted { $0.magnitude > $1.magnitude }
    }
}
