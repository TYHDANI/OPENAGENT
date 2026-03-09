import Foundation

enum RoomType: String, Codable, CaseIterable {
    case bedroom, livingRoom, kitchen, bathroom, office, nursery, basement, garage, outdoor

    var label: String {
        switch self {
        case .bedroom: "Bedroom"
        case .livingRoom: "Living Room"
        case .kitchen: "Kitchen"
        case .bathroom: "Bathroom"
        case .office: "Office"
        case .nursery: "Nursery"
        case .basement: "Basement"
        case .garage: "Garage"
        case .outdoor: "Outdoor"
        }
    }

    var icon: String {
        switch self {
        case .bedroom: "bed.double.fill"
        case .livingRoom: "sofa.fill"
        case .kitchen: "fork.knife"
        case .bathroom: "shower.fill"
        case .office: "desktopcomputer"
        case .nursery: "figure.and.child.holdinghands"
        case .basement: "stairs"
        case .garage: "car.fill"
        case .outdoor: "tree.fill"
        }
    }
}

struct Room: Identifiable, Codable {
    let id: UUID
    var propertyID: UUID
    var name: String
    var type: RoomType
    var latestReading: AirReading?
    var hasFilter: Bool
    var filterInstalledDate: Date?
    var filterLifespanDays: Int

    init(id: UUID = UUID(), propertyID: UUID, name: String, type: RoomType,
         hasFilter: Bool = false, filterLifespanDays: Int = 90) {
        self.id = id; self.propertyID = propertyID; self.name = name; self.type = type
        self.latestReading = nil; self.hasFilter = hasFilter
        self.filterInstalledDate = hasFilter ? Date() : nil; self.filterLifespanDays = filterLifespanDays
    }

    var filterDaysRemaining: Int? {
        guard hasFilter, let installed = filterInstalledDate else { return nil }
        let elapsed = Calendar.current.dateComponents([.day], from: installed, to: Date()).day ?? 0
        return max(0, filterLifespanDays - elapsed)
    }

    var needsFilterChange: Bool {
        guard let remaining = filterDaysRemaining else { return false }
        return remaining <= 7
    }
}
