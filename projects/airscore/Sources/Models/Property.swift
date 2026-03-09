import Foundation

enum PropertyType: String, Codable, CaseIterable {
    case home, apartment, office, commercial, warehouse

    var label: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .home: "house.fill"
        case .apartment: "building.fill"
        case .office: "building.2.fill"
        case .commercial: "storefront.fill"
        case .warehouse: "shippingbox.fill"
        }
    }
}

struct Property: Identifiable, Codable {
    let id: UUID
    var name: String
    var address: String
    var type: PropertyType
    var rooms: [Room]
    var isFleetProperty: Bool   // B2B fleet vs personal B2C

    init(id: UUID = UUID(), name: String, address: String = "", type: PropertyType = .home,
         rooms: [Room] = [], isFleetProperty: Bool = false) {
        self.id = id; self.name = name; self.address = address; self.type = type
        self.rooms = rooms; self.isFleetProperty = isFleetProperty
    }

    var overallAQI: Int {
        let readings = rooms.compactMap { $0.latestReading?.aqi }
        guard !readings.isEmpty else { return 0 }
        return readings.reduce(0, +) / readings.count
    }

    var overallLevel: AQILevel { AQILevel.from(aqi: overallAQI) }
    var filtersNeedingChange: Int { rooms.filter { $0.needsFilterChange }.count }
}
