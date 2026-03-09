import Foundation

actor RadarService {
    private let radarURL = "https://api.rainviewer.com/public/weather-maps.json"
    private let session = URLSession.shared

    func fetchRadarFrames() async throws -> (String, [RainViewerFrame]) {
        let url = URL(string: radarURL)!
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(RainViewerResponse.self, from: data)

        var allFrames = response.radar.past
        if let nowcast = response.radar.nowcast {
            allFrames.append(contentsOf: nowcast)
        }

        return (response.host, allFrames)
    }

    /// Build tile URL for a specific radar frame
    func radarTileURL(host: String, frame: RainViewerFrame, z: Int, x: Int, y: Int, colorScheme: Int = 6, smooth: Int = 1, snow: Int = 1) -> URL? {
        // Format: {host}{path}/{size}/{z}/{x}/{y}/{color}/{smooth}_{snow}.png
        URL(string: "\(host)\(frame.path)/512/\(z)/\(x)/\(y)/\(colorScheme)/\(smooth)_\(snow).png")
    }
}
