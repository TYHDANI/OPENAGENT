import Foundation

actor MaxarService {
    private let catalogURL = "https://maxar-opendata.s3.amazonaws.com/events/catalog.json"
    private let session = URLSession.shared

    /// Fetch the Maxar STAC root catalog to list all disaster events
    func fetchEvents() async throws -> [MaxarEvent] {
        let url = URL(string: catalogURL)!
        let (data, _) = try await session.data(from: url)
        let catalog = try JSONDecoder().decode(STACCatalog.self, from: data)

        // Parse child links to build event list
        let childLinks = catalog.links.filter { $0.rel == "child" }

        return childLinks.compactMap { link -> MaxarEvent? in
            let id = link.href.components(separatedBy: "/").last?.replacingOccurrences(of: ".json", with: "") ?? link.href
            return MaxarEvent(
                id: id,
                title: link.title ?? id.replacingOccurrences(of: "-", with: " ").capitalized,
                description: nil,
                bbox: eventBBox(for: id),
                links: [link]
            )
        }
    }

    /// Known bounding boxes for major Maxar Open Data events
    private func eventBBox(for eventId: String) -> [Double]? {
        let bboxes: [String: [Double]] = [
            "Morocco-Earthquake-Sept-2023": [-9.5, 30.5, -7.5, 32.5],
            "Hurricane-Ian-9-26-2022": [-83.0, 25.5, -80.0, 28.5],
            "pakistan-flooding22": [65.0, 24.0, 76.0, 37.0],
            "Kahramanmaras-turkey-earthquake-23": [35.0, 36.0, 38.0, 38.5],
            "southafrica-flooding22": [29.5, -30.5, 31.5, -29.0],
            "Hurricane-Idalia-Florida-Aug23": [-84.0, 28.0, -82.0, 31.0],
            "cyclone-emnati22": [43.0, -24.0, 51.0, -12.0],
            "afghanistan-earthquake22": [67.0, 32.0, 71.0, 35.0],
            "tonga-volcano21": [-176.5, -22.0, -174.5, -19.5],
            "yellowstone-flooding22": [-111.5, 44.0, -109.5, 46.0],
            "volcano-indonesia21": [119.0, -9.0, 123.0, -7.0],
            "BayofBengal-Cyclone-Mocha-May-23": [90.0, 18.0, 96.0, 22.0],
            "Emilia-Romagna-Italy-flooding-may23": [11.0, 43.5, 13.0, 45.0],
            "Hurricane-Fiona-9-19-2022": [-68.0, 17.0, -64.0, 19.0],
            "ghana-explosion22": [-2.5, 5.0, 0.0, 8.0],
            "Libya-Floods-Sept-2023": [20.0, 31.0, 24.0, 34.0],
            "kentucky-flooding-7-29-2022": [-84.0, 37.0, -82.0, 38.5],
            "Maui-Hawaii-fires-Aug-23": [-157.0, 20.5, -155.5, 21.5],
            "Indonesia-Earthquake22": [118.0, -8.5, 120.0, -6.5],
            "NWT-Canada-Aug-23": [-120.0, 60.0, -110.0, 65.0],
            "Gambia-flooding-8-11-2022": [-17.5, 13.0, -13.5, 14.0],
            "Sudan-flooding-8-22-2022": [31.0, 13.0, 35.0, 20.0],
            "India-Floods-Oct-2023": [78.0, 10.0, 82.0, 14.0],
            "McDougallCreekWildfire-BC-Canada-Aug-23": [-120.0, 49.5, -118.0, 51.0],
            "New-Zealand-Flooding23": [174.0, -42.0, 178.0, -36.0],
            "Kalehe-DRC-Flooding-5-8-23": [28.0, -3.5, 30.0, -1.5],
            "shovi-georgia-landslide-8Aug23": [43.0, 42.0, 44.5, 43.0],
            "Marshall-Fire-21-Update": [-105.5, 39.5, -104.5, 40.5],
        ]
        return bboxes[eventId]
    }
}
