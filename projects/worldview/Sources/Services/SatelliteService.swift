import Foundation

actor SatelliteService {
    private let baseURL = "https://celestrak.org/NORAD/elements/gp.php"
    private let session = URLSession.shared

    func fetchGroup(_ group: SatelliteGroup) async throws -> [SatelliteGP] {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "GROUP", value: group.rawValue),
            URLQueryItem(name: "FORMAT", value: "json"),
        ]
        let (data, _) = try await session.data(from: components.url!)
        return try JSONDecoder().decode([SatelliteGP].self, from: data)
    }

    func fetchAndPropagate(groups: [SatelliteGroup]) async throws -> [SatellitePosition] {
        var positions: [SatellitePosition] = []
        let now = Date()

        for group in groups {
            let sats = try await fetchGroup(group)
            // Limit propagation to keep things responsive
            let limit = group == .starlink ? 200 : sats.count
            for sat in sats.prefix(limit) {
                if let pos = SimpleSGP4.propagate(satellite: sat, to: now) {
                    positions.append(pos)
                }
            }
        }

        return positions
    }

    func fetchSingle(noradId: Int) async throws -> SatelliteGP {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "CATNR", value: "\(noradId)"),
            URLQueryItem(name: "FORMAT", value: "json"),
        ]
        let (data, _) = try await session.data(from: components.url!)
        let results = try JSONDecoder().decode([SatelliteGP].self, from: data)
        guard let first = results.first else {
            throw URLError(.badServerResponse)
        }
        return first
    }
}
