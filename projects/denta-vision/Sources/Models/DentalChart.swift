import Foundation

/// Represents a dental chart with tooth conditions and treatment notes
struct DentalChart: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    var teeth: [Tooth]
    var periodontalData: PeriodontalChart?
    var notes: String

    /// Timestamp for voice recording session
    var recordingDate: Date

    /// Duration of the voice recording (if applicable)
    var recordingDuration: TimeInterval?

    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        patientId: UUID,
        teeth: [Tooth] = Tooth.createFullMouth(),
        periodontalData: PeriodontalChart? = nil,
        notes: String = "",
        recordingDate: Date = Date()
    ) {
        self.id = id
        self.patientId = patientId
        self.teeth = teeth
        self.periodontalData = periodontalData
        self.notes = notes
        self.recordingDate = recordingDate
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// Represents an individual tooth with conditions and treatments
struct Tooth: Codable, Identifiable, Hashable {
    let id: UUID
    let number: Int // Universal numbering system (1-32)
    var conditions: [ToothCondition]
    var treatments: [Treatment]
    var notes: String

    init(
        id: UUID = UUID(),
        number: Int,
        conditions: [ToothCondition] = [],
        treatments: [Treatment] = [],
        notes: String = ""
    ) {
        self.id = id
        self.number = number
        self.conditions = conditions
        self.treatments = treatments
        self.notes = notes
    }

    /// Creates a full set of teeth (32 teeth for adults)
    static func createFullMouth() -> [Tooth] {
        (1...32).map { Tooth(number: $0) }
    }

    /// Returns the tooth name based on universal numbering
    var name: String {
        switch number {
        case 1, 16: return "Third Molar"
        case 2, 15, 18, 31: return "Second Molar"
        case 3, 14, 19, 30: return "First Molar"
        case 4, 13, 20, 29: return "Second Premolar"
        case 5, 12, 21, 28: return "First Premolar"
        case 6, 11, 22, 27: return "Canine"
        case 7, 10, 23, 26: return "Lateral Incisor"
        case 8, 9, 24, 25: return "Central Incisor"
        case 17, 32: return "Third Molar (Wisdom)"
        default: return "Tooth \(number)"
        }
    }

    /// Returns the tooth location (quadrant)
    var quadrant: String {
        switch number {
        case 1...8: return "Upper Right"
        case 9...16: return "Upper Left"
        case 17...24: return "Lower Left"
        case 25...32: return "Lower Right"
        default: return "Unknown"
        }
    }
}

/// Common tooth conditions
enum ToothCondition: String, Codable, CaseIterable {
    case healthy = "Healthy"
    case cavity = "Cavity"
    case filling = "Filling"
    case crown = "Crown"
    case rootCanal = "Root Canal"
    case missing = "Missing"
    case implant = "Implant"
    case bridge = "Bridge"
    case crack = "Crack"
    case decay = "Decay"
    case abscess = "Abscess"
    case gingivitis = "Gingivitis"
    case periodontitis = "Periodontitis"
}

/// Dental treatments
struct Treatment: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    var type: TreatmentType
    var toothNumbers: [Int]
    var description: String
    var estimatedCost: Decimal
    var insuranceCoverage: Decimal?
    var priority: TreatmentPriority
    var dateProposed: Date
    var dateCompleted: Date?

    init(
        id: UUID = UUID(),
        type: TreatmentType,
        toothNumbers: [Int],
        description: String,
        estimatedCost: Decimal,
        insuranceCoverage: Decimal? = nil,
        priority: TreatmentPriority = .moderate,
        dateProposed: Date = Date(),
        dateCompleted: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.toothNumbers = toothNumbers
        self.description = description
        self.estimatedCost = estimatedCost
        self.insuranceCoverage = insuranceCoverage
        self.priority = priority
        self.dateProposed = dateProposed
        self.dateCompleted = dateCompleted
    }
}

/// Treatment types
enum TreatmentType: String, Codable, CaseIterable {
    case filling = "Filling"
    case crown = "Crown"
    case rootCanal = "Root Canal"
    case extraction = "Extraction"
    case implant = "Implant"
    case bridge = "Bridge"
    case veneer = "Veneer"
    case cleaning = "Cleaning"
    case deepCleaning = "Deep Cleaning"
    case orthodontics = "Orthodontics"
    case whitening = "Whitening"
    case other = "Other"
}

/// Treatment priority levels
enum TreatmentPriority: String, Codable, CaseIterable {
    case urgent = "Urgent"
    case high = "High"
    case moderate = "Moderate"
    case low = "Low"
    case elective = "Elective"
}

/// Periodontal charting data
struct PeriodontalChart: Codable {
    var pocketDepths: [Int: [Int]] // Tooth number to 6 measurements
    var bleedingOnProbing: [Int: Bool]
    var recession: [Int: [Int]]
    var mobility: [Int: Int] // 0-3 scale
    var furcation: [Int: Int] // 0-3 scale
}