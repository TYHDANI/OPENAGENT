import Foundation
import CoreLocation

/// Service for WiFi-based sensing intelligence (inspired by RuView/WiFi-DensePose)
/// Connects to RuView REST API or generates simulated data for globe overlay
actor RFSensingService {

    // MARK: - RuView API Integration

    /// Fetch sensor nodes from a RuView deployment
    func fetchSensorNodes(baseURL: String = "") async throws -> [WiFiSensorNode] {
        // In production, connects to RuView API: GET /api/v1/sensing/nodes
        // For now, generate simulated global sensor mesh
        return generateSimulatedNodes()
    }

    /// Fetch presence detections from sensor mesh
    func fetchPresenceDetections(baseURL: String = "") async throws -> [PresenceDetection] {
        // In production: GET /api/v1/sensing/latest + WebSocket /ws/sensing
        return generateSimulatedPresence()
    }

    /// Fetch vital signs from WiFi CSI analysis
    func fetchVitalSigns(baseURL: String = "") async throws -> [WiFiVitalSigns] {
        // In production: GET /api/v1/vital-signs
        return generateSimulatedVitals()
    }

    /// Fetch disaster survivor detections (WiFi-MAT mode)
    func fetchDisasterSurvivors(nearEarthquakes: [EarthquakePin]) async throws -> [DisasterSurvivor] {
        // In production: GET /api/v1/mat/survivors
        // Simulated: generate survivors near major earthquake epicenters
        return generateSimulatedSurvivors(nearEarthquakes: nearEarthquakes)
    }

    /// Fetch RF interference zones
    func fetchRFInterference() async throws -> [RFInterferenceZone] {
        return generateSimulatedInterference()
    }

    // MARK: - Simulated Data Generation

    private func generateSimulatedNodes() -> [WiFiSensorNode] {
        let deployments: [(String, Double, Double, [String])] = [
            // Critical infrastructure monitoring
            ("Pentagon Perimeter", 38.8711, -77.0559, ["presence", "coherence_gate", "anomaly_detect"]),
            ("Capitol Building", 38.8899, -77.0091, ["presence", "vital_signs", "replay_detect"]),
            ("UN HQ NYC", 40.7489, -73.9680, ["presence", "gesture_classify"]),
            ("NATO Brussels", 50.8770, 4.4250, ["presence", "coherence_gate"]),
            ("CERN Geneva", 46.2330, 6.0557, ["rf_tomography", "field_model"]),
            // Disaster response staging
            ("FEMA Region IV", 33.7490, -84.3880, ["mat_survivor", "vital_signs", "triage"]),
            ("Red Cross Geneva", 46.2264, 6.1390, ["mat_survivor", "breathing_detect"]),
            // Research installations
            ("CMU WiFi Lab", 40.4433, -79.9436, ["full_densepose", "microloRA", "aether"]),
            ("MIT CSAIL", 42.3616, -71.0903, ["csi_process", "pose_estimation"]),
            ("Stanford HAI", 37.4275, -122.1697, ["federated_learn", "domain_generalize"]),
            // Border / security
            ("El Paso Port", 31.7587, -106.4869, ["presence", "count", "anomaly_detect"]),
            ("Dover Port UK", 51.1295, 1.3089, ["presence", "vital_signs"]),
        ]

        return deployments.map { name, lat, lon, modules in
            WiFiSensorNode(
                name: name,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                status: Bool.random() ? .online : (Bool.random() ? .degraded : .online),
                signalStrength: Double.random(in: -65 ... -30),
                csiSubcarriers: [64, 128, 192].randomElement() ?? 64,
                streamingHz: 28,
                edgeModules: modules
            )
        }
    }

    private func generateSimulatedPresence() -> [PresenceDetection] {
        let nodes = generateSimulatedNodes()
        return nodes.prefix(8).map { node in
            PresenceDetection(
                sensorNodeID: node.id,
                coordinate: CLLocationCoordinate2D(
                    latitude: node.coordinate.latitude + Double.random(in: -0.001...0.001),
                    longitude: node.coordinate.longitude + Double.random(in: -0.001...0.001)
                ),
                personCount: Int.random(in: 1...5),
                motionState: [.still, .moving, .active].randomElement() ?? .still,
                confidence: Double.random(in: 0.72...0.98),
                distanceMeters: Double.random(in: 0.5...3.0),
                throughWall: Bool.random()
            )
        }
    }

    private func generateSimulatedVitals() -> [WiFiVitalSigns] {
        let nodes = generateSimulatedNodes()
        return nodes.prefix(6).map { node in
            WiFiVitalSigns(
                sensorNodeID: node.id,
                coordinate: node.coordinate,
                breathingRate: Double.random(in: 12...20),
                heartRate: Double.random(in: 58...85),
                breathingConfidence: Double.random(in: 0.85...0.98),
                heartRateConfidence: Double.random(in: 0.6...0.92),
                signalQuality: [.excellent, .good, .moderate].randomElement() ?? .good
            )
        }
    }

    private func generateSimulatedSurvivors(nearEarthquakes: [EarthquakePin]) -> [DisasterSurvivor] {
        // Place simulated survivors near major earthquakes (M5.0+)
        let majorQuakes = nearEarthquakes.filter { $0.magnitude >= 5.0 }
        return majorQuakes.prefix(3).flatMap { quake -> [DisasterSurvivor] in
            (0..<Int.random(in: 2...6)).map { _ in
                DisasterSurvivor(
                    coordinate: CLLocationCoordinate2D(
                        latitude: quake.coordinate.latitude + Double.random(in: -0.05...0.05),
                        longitude: quake.coordinate.longitude + Double.random(in: -0.05...0.05)
                    ),
                    triageColor: [.green, .yellow, .red].randomElement() ?? .yellow,
                    breathingDetected: Bool.random(),
                    movementDetected: Bool.random(),
                    estimatedDepthMeters: Double.random(in: 0...2.5),
                    confidenceScore: Double.random(in: 0.65...0.95)
                )
            }
        }
    }

    private func generateSimulatedInterference() -> [RFInterferenceZone] {
        let zones: [(Double, Double, String, RFInterferenceZone.InterferenceType)] = [
            (36.20, 36.15, "Aleppo Region", .jamming),
            (50.45, 30.52, "Kyiv Area", .jamming),
            (33.31, 44.37, "Baghdad", .interference),
            (25.28, 51.53, "Doha", .spoofing),
            (64.18, -51.72, "Greenland SIGINT", .anomaly),
        ]

        return zones.map { lat, lon, source, type in
            RFInterferenceZone(
                id: UUID(),
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                radiusKm: Double.random(in: 10...100),
                interferenceType: type,
                severity: Double.random(in: 0.4...0.95),
                affectedFrequencyGHz: [2.4, 5.0, 5.8].randomElement() ?? 2.4,
                source: source,
                detectedAt: Date()
            )
        }
    }
}
