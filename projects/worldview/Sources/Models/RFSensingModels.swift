import Foundation
import CoreLocation

// MARK: - WiFi Sensing Node (from RuView ESP32 mesh)

struct WiFiSensorNode: Identifiable, Codable, Sendable {
    let id: UUID
    var name: String
    var coordinate: CLLocationCoordinate2D
    var status: NodeStatus
    var signalStrength: Double   // dBm
    var csiSubcarriers: Int      // 64/128/192
    var streamingHz: Double      // typically 28 Hz
    var lastSeen: Date
    var firmwareVersion: String
    var edgeModules: [String]    // loaded WASM modules

    enum NodeStatus: String, Codable, Sendable {
        case online, degraded, offline, calibrating
    }

    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude, status, signalStrength, csiSubcarriers
        case streamingHz, lastSeen, firmwareVersion, edgeModules
    }

    init(id: UUID = UUID(), name: String, coordinate: CLLocationCoordinate2D,
         status: NodeStatus = .online, signalStrength: Double = -45,
         csiSubcarriers: Int = 64, streamingHz: Double = 28,
         firmwareVersion: String = "3.2.0", edgeModules: [String] = []) {
        self.id = id; self.name = name; self.coordinate = coordinate
        self.status = status; self.signalStrength = signalStrength
        self.csiSubcarriers = csiSubcarriers; self.streamingHz = streamingHz
        self.lastSeen = Date(); self.firmwareVersion = firmwareVersion
        self.edgeModules = edgeModules
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        let lat = try c.decode(Double.self, forKey: .latitude)
        let lon = try c.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        status = try c.decode(NodeStatus.self, forKey: .status)
        signalStrength = try c.decode(Double.self, forKey: .signalStrength)
        csiSubcarriers = try c.decode(Int.self, forKey: .csiSubcarriers)
        streamingHz = try c.decode(Double.self, forKey: .streamingHz)
        lastSeen = try c.decode(Date.self, forKey: .lastSeen)
        firmwareVersion = try c.decode(String.self, forKey: .firmwareVersion)
        edgeModules = try c.decode([String].self, forKey: .edgeModules)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(coordinate.latitude, forKey: .latitude)
        try c.encode(coordinate.longitude, forKey: .longitude)
        try c.encode(status, forKey: .status)
        try c.encode(signalStrength, forKey: .signalStrength)
        try c.encode(csiSubcarriers, forKey: .csiSubcarriers)
        try c.encode(streamingHz, forKey: .streamingHz)
        try c.encode(lastSeen, forKey: .lastSeen)
        try c.encode(firmwareVersion, forKey: .firmwareVersion)
        try c.encode(edgeModules, forKey: .edgeModules)
    }
}

// MARK: - Presence Detection (through-wall human sensing)

struct PresenceDetection: Identifiable, Sendable {
    let id: UUID
    var sensorNodeID: UUID
    var coordinate: CLLocationCoordinate2D
    var personCount: Int
    var motionState: MotionState
    var confidence: Double       // 0-1
    var distanceMeters: Double   // from sensor
    var throughWall: Bool
    var timestamp: Date

    enum MotionState: String, Sendable {
        case still, moving, active, fallen
        var icon: String {
            switch self {
            case .still: "person.fill"
            case .moving: "figure.walk"
            case .active: "figure.run"
            case .fallen: "figure.fall"
            }
        }
    }

    init(id: UUID = UUID(), sensorNodeID: UUID, coordinate: CLLocationCoordinate2D,
         personCount: Int = 1, motionState: MotionState = .still,
         confidence: Double = 0.85, distanceMeters: Double = 2.0,
         throughWall: Bool = false) {
        self.id = id; self.sensorNodeID = sensorNodeID; self.coordinate = coordinate
        self.personCount = personCount; self.motionState = motionState
        self.confidence = confidence; self.distanceMeters = distanceMeters
        self.throughWall = throughWall; self.timestamp = Date()
    }
}

// MARK: - Vital Signs from WiFi (non-contact)

struct WiFiVitalSigns: Identifiable, Sendable {
    let id: UUID
    var sensorNodeID: UUID
    var coordinate: CLLocationCoordinate2D
    var breathingRate: Double     // BPM (6-30 normal)
    var heartRate: Double         // BPM (40-120 detectable)
    var breathingConfidence: Double
    var heartRateConfidence: Double
    var signalQuality: SignalQuality
    var timestamp: Date

    enum SignalQuality: String, Sendable {
        case excellent, good, moderate, poor
        var color: String {
            switch self {
            case .excellent: "#4CAF50"
            case .good: "#8BC34A"
            case .moderate: "#FFC107"
            case .poor: "#F44336"
            }
        }
    }

    init(id: UUID = UUID(), sensorNodeID: UUID, coordinate: CLLocationCoordinate2D,
         breathingRate: Double, heartRate: Double,
         breathingConfidence: Double = 0.9, heartRateConfidence: Double = 0.75,
         signalQuality: SignalQuality = .good) {
        self.id = id; self.sensorNodeID = sensorNodeID; self.coordinate = coordinate
        self.breathingRate = breathingRate; self.heartRate = heartRate
        self.breathingConfidence = breathingConfidence; self.heartRateConfidence = heartRateConfidence
        self.signalQuality = signalQuality; self.timestamp = Date()
    }
}

// MARK: - Disaster Survivor Detection (WiFi-MAT from RuView)

struct DisasterSurvivor: Identifiable, Sendable {
    let id: UUID
    var coordinate: CLLocationCoordinate2D
    var triageColor: TriageColor
    var breathingDetected: Bool
    var movementDetected: Bool
    var estimatedDepthMeters: Double  // depth under rubble
    var confidenceScore: Double
    var detectedBy: [UUID]           // sensor node IDs
    var timestamp: Date
    var disasterEventID: UUID?

    enum TriageColor: String, Sendable {
        case green   // Walking wounded, minor injuries
        case yellow  // Delayed, significant injuries but stable
        case red     // Immediate, life-threatening
        case black   // Deceased or expectant

        var label: String {
            switch self {
            case .green: "Minor"
            case .yellow: "Delayed"
            case .red: "Immediate"
            case .black: "Expectant"
            }
        }

        var colorHex: String {
            switch self {
            case .green: "#4CAF50"
            case .yellow: "#FFEB3B"
            case .red: "#F44336"
            case .black: "#212121"
            }
        }
    }

    init(id: UUID = UUID(), coordinate: CLLocationCoordinate2D,
         triageColor: TriageColor = .yellow, breathingDetected: Bool = true,
         movementDetected: Bool = false, estimatedDepthMeters: Double = 0,
         confidenceScore: Double = 0.8, detectedBy: [UUID] = []) {
        self.id = id; self.coordinate = coordinate; self.triageColor = triageColor
        self.breathingDetected = breathingDetected; self.movementDetected = movementDetected
        self.estimatedDepthMeters = estimatedDepthMeters; self.confidenceScore = confidenceScore
        self.detectedBy = detectedBy; self.timestamp = Date(); self.disasterEventID = nil
    }
}

// MARK: - RF Signal Interference Zone

struct RFInterferenceZone: Identifiable, Sendable {
    let id: UUID
    var coordinate: CLLocationCoordinate2D
    var radiusKm: Double
    var interferenceType: InterferenceType
    var severity: Double         // 0-1
    var affectedFrequencyGHz: Double
    var source: String
    var detectedAt: Date

    enum InterferenceType: String, Sendable {
        case jamming, spoofing, interference, anomaly
        var icon: String {
            switch self {
            case .jamming: "antenna.radiowaves.left.and.right.slash"
            case .spoofing: "exclamationmark.shield"
            case .interference: "waveform.path.ecg.rectangle"
            case .anomaly: "questionmark.diamond"
            }
        }
    }
}

// MARK: - Pose Keypoint (17 COCO keypoints from WiFi CSI)

struct PoseKeypoint: Identifiable, Sendable {
    let id: UUID
    var jointName: String
    var x: Double
    var y: Double
    var z: Double
    var confidence: Double

    static let cocoJoints = [
        "nose", "left_eye", "right_eye", "left_ear", "right_ear",
        "left_shoulder", "right_shoulder", "left_elbow", "right_elbow",
        "left_wrist", "right_wrist", "left_hip", "right_hip",
        "left_knee", "right_knee", "left_ankle", "right_ankle"
    ]
}
