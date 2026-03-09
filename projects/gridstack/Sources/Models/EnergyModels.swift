import Foundation

// MARK: - Energy Reading

struct EnergyReading: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let consumptionKWh: Double
    let generationKWh: Double
    let costUSD: Double
    let source: EnergySource

    enum EnergySource: String, Codable, CaseIterable {
        case grid = "Grid"
        case solar = "Solar"
        case battery = "Battery"
        case heatReclaim = "Heat Reclaim"
    }

    var netUsageKWh: Double {
        consumptionKWh - generationKWh
    }

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        consumptionKWh: Double,
        generationKWh: Double = 0,
        costUSD: Double,
        source: EnergySource = .grid
    ) {
        self.id = id
        self.timestamp = timestamp
        self.consumptionKWh = consumptionKWh
        self.generationKWh = generationKWh
        self.costUSD = costUSD
        self.source = source
    }
}

// MARK: - Demand Response Event

struct DemandResponseEvent: Identifiable, Codable {
    let id: UUID
    let programName: String
    let eventDate: Date
    let durationMinutes: Int
    let status: DREventStatus
    let earningsUSD: Double
    let kWhReduced: Double
    let eventType: DREventType

    enum DREventStatus: String, Codable, CaseIterable {
        case upcoming = "Upcoming"
        case active = "Active"
        case completed = "Completed"
        case missed = "Missed"
    }

    enum DREventType: String, Codable, CaseIterable {
        case thermostatAdjust = "Thermostat Adjust"
        case loadShift = "Load Shift"
        case batteryDispatch = "Battery Dispatch"
        case evChargeDefer = "EV Charge Defer"
    }

    var endDate: Date {
        eventDate.addingTimeInterval(TimeInterval(durationMinutes * 60))
    }

    init(
        id: UUID = UUID(),
        programName: String,
        eventDate: Date,
        durationMinutes: Int,
        status: DREventStatus,
        earningsUSD: Double,
        kWhReduced: Double,
        eventType: DREventType = .thermostatAdjust
    ) {
        self.id = id
        self.programName = programName
        self.eventDate = eventDate
        self.durationMinutes = durationMinutes
        self.status = status
        self.earningsUSD = earningsUSD
        self.kWhReduced = kWhReduced
        self.eventType = eventType
    }
}

// MARK: - Mining Session

struct MiningSession: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    let endTime: Date?
    let hashRateTHs: Double
    let powerConsumptionW: Double
    let btcEarned: Double
    let electricityCostUSD: Double
    let heatOutputBTU: Double
    let heatReclaimed: Bool
    let algorithm: MiningAlgorithm

    enum MiningAlgorithm: String, Codable, CaseIterable {
        case sha256 = "SHA-256"
        case ethash = "Ethash"
        case scrypt = "Scrypt"
        case randomX = "RandomX"
    }

    var isActive: Bool {
        endTime == nil
    }

    var durationHours: Double {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime) / 3600
    }

    var electricityCostPerKWh: Double {
        let kWh = (powerConsumptionW / 1000.0) * durationHours
        guard kWh > 0 else { return 0 }
        return electricityCostUSD / kWh
    }

    var heatReclaimSavingsUSD: Double {
        guard heatReclaimed else { return 0 }
        // Average US natural gas cost ~$1.20 per therm (100,000 BTU)
        return (heatOutputBTU / 100_000) * 1.20
    }

    var netProfitUSD: Double {
        btcEarned * 60_000 - electricityCostUSD + heatReclaimSavingsUSD
    }

    var roiPercent: Double {
        guard electricityCostUSD > 0 else { return 0 }
        return ((btcEarned * 60_000 + heatReclaimSavingsUSD - electricityCostUSD) / electricityCostUSD) * 100
    }

    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date? = nil,
        hashRateTHs: Double,
        powerConsumptionW: Double,
        btcEarned: Double,
        electricityCostUSD: Double,
        heatOutputBTU: Double,
        heatReclaimed: Bool = true,
        algorithm: MiningAlgorithm = .sha256
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.hashRateTHs = hashRateTHs
        self.powerConsumptionW = powerConsumptionW
        self.btcEarned = btcEarned
        self.electricityCostUSD = electricityCostUSD
        self.heatOutputBTU = heatOutputBTU
        self.heatReclaimed = heatReclaimed
        self.algorithm = algorithm
    }
}

// MARK: - Prosumer Profile

struct ProsumerProfile: Codable {
    var displayName: String
    var homeSize: HomeSize
    var hvacType: HVACType
    var smartThermostat: ThermostatBrand?
    var hasSolar: Bool
    var hasBattery: Bool
    var hasMiningRig: Bool
    var certifications: [ProsumerCertification]
    var utilityProvider: String
    var electricityRatePerKWh: Double
    var state: String

    enum HomeSize: String, Codable, CaseIterable {
        case small = "< 1,500 sqft"
        case medium = "1,500 - 2,500 sqft"
        case large = "2,500 - 4,000 sqft"
        case xlarge = "4,000+ sqft"
    }

    enum HVACType: String, Codable, CaseIterable {
        case centralAC = "Central AC"
        case heatPump = "Heat Pump"
        case minisplit = "Mini-Split"
        case window = "Window Unit"
        case radiant = "Radiant"
    }

    enum ThermostatBrand: String, Codable, CaseIterable {
        case nest = "Google Nest"
        case ecobee = "Ecobee"
        case honeywell = "Honeywell"
        case other = "Other"
        case none = "None"
    }

    struct ProsumerCertification: Identifiable, Codable {
        let id: UUID
        let name: String
        let description: String
        let icon: String
        var isCompleted: Bool

        init(
            id: UUID = UUID(),
            name: String,
            description: String,
            icon: String,
            isCompleted: Bool = false
        ) {
            self.id = id
            self.name = name
            self.description = description
            self.icon = icon
            self.isCompleted = isCompleted
        }
    }

    static var `default`: ProsumerProfile {
        ProsumerProfile(
            displayName: "Homeowner",
            homeSize: .medium,
            hvacType: .centralAC,
            smartThermostat: .nest,
            hasSolar: false,
            hasBattery: false,
            hasMiningRig: true,
            certifications: defaultCertifications,
            utilityProvider: "PG&E",
            electricityRatePerKWh: 0.32,
            state: "CA"
        )
    }

    static var defaultCertifications: [ProsumerCertification] {
        [
            ProsumerCertification(
                name: "Smart Thermostat Connected",
                description: "Connect a compatible smart thermostat to GridStack",
                icon: "thermometer",
                isCompleted: true
            ),
            ProsumerCertification(
                name: "First DR Event",
                description: "Participate in your first demand response event",
                icon: "bolt.circle",
                isCompleted: true
            ),
            ProsumerCertification(
                name: "Heat Reclaimer",
                description: "Log your first mining session with heat reclamation",
                icon: "flame",
                isCompleted: true
            ),
            ProsumerCertification(
                name: "Energy Exporter",
                description: "Export energy back to the grid via solar or battery",
                icon: "arrow.up.circle",
                isCompleted: false
            ),
            ProsumerCertification(
                name: "Week Streak",
                description: "Participate in DR events for 7 consecutive days",
                icon: "calendar.badge.clock",
                isCompleted: false
            ),
            ProsumerCertification(
                name: "Carbon Negative",
                description: "Offset more carbon than you consumed in a month",
                icon: "leaf.circle",
                isCompleted: false
            ),
            ProsumerCertification(
                name: "$100 Club",
                description: "Earn over $100 in total energy earnings",
                icon: "dollarsign.circle",
                isCompleted: false
            ),
            ProsumerCertification(
                name: "Grid Guardian",
                description: "Complete 50 demand response events",
                icon: "shield.checkered",
                isCompleted: false
            )
        ]
    }
}

// MARK: - Earnings Record

struct EarningsRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let amount: Double
    let source: EarningsSource
    let description: String

    enum EarningsSource: String, Codable, CaseIterable {
        case demandResponse = "Demand Response"
        case mining = "Mining"
        case heatReclamation = "Heat Reclamation"
        case touSavings = "TOU Savings"
        case solarExport = "Solar Export"
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        amount: Double,
        source: EarningsSource,
        description: String
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.source = source
        self.description = description
    }
}

// MARK: - Time Period

enum TimePeriod: String, CaseIterable {
    case day = "Today"
    case week = "This Week"
    case month = "This Month"
    case year = "This Year"
}
