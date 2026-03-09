import SwiftUI

/// RF Intelligence view — WiFi sensing mesh, presence detection,
/// vital signs, disaster response, and RF interference (RuView integration)
struct RFSensingView: View {
    @Environment(DataOrchestrator.self) private var data
    @State private var selectedSubsection: RFSubsection = .mesh

    enum RFSubsection: String, CaseIterable {
        case mesh = "Sensor Mesh"
        case presence = "Presence"
        case vitals = "Vital Signs"
        case disaster = "Disaster"
        case interference = "RF Threats"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Sub-section picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(RFSubsection.allCases, id: \.self) { sub in
                        Button {
                            selectedSubsection = sub
                        } label: {
                            Text(sub.rawValue)
                                .font(NETheme.caption())
                                .foregroundStyle(selectedSubsection == sub ? .white : NETheme.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(selectedSubsection == sub ? NETheme.accent : NETheme.surfaceOverlay)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 6)

            ScrollView {
                switch selectedSubsection {
                case .mesh: sensorMeshView
                case .presence: presenceView
                case .vitals: vitalsView
                case .disaster: disasterView
                case .interference: interferenceView
                }
            }
        }
    }

    // MARK: - Sensor Mesh

    private var sensorMeshView: some View {
        LazyVStack(spacing: 10) {
            // Header stats
            HStack(spacing: 12) {
                RFStatCard(title: "Nodes", value: "\(data.sensorNodes.count)",
                           icon: "wifi.router", color: NETheme.accent)
                RFStatCard(title: "Online", value: "\(data.sensorNodes.filter { $0.status == .online }.count)",
                           icon: "checkmark.circle", color: NETheme.severityLow)
                RFStatCard(title: "Degraded", value: "\(data.sensorNodes.filter { $0.status == .degraded }.count)",
                           icon: "exclamationmark.triangle", color: NETheme.severityMedium)
            }
            .padding(.horizontal)

            Text("WiFi-DensePose Sensor Network")
                .font(NETheme.mono(10))
                .foregroundStyle(NETheme.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ForEach(data.sensorNodes) { node in
                HStack(spacing: 12) {
                    Circle()
                        .fill(node.status == .online ? NETheme.severityLow :
                              node.status == .degraded ? NETheme.severityMedium : NETheme.severityCritical)
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(node.name)
                            .font(NETheme.subheading(13))
                            .foregroundStyle(NETheme.textPrimary)
                        HStack(spacing: 8) {
                            Text("\(node.csiSubcarriers) subcarriers")
                            Text("\(String(format: "%.0f", node.streamingHz)) Hz")
                            Text("\(String(format: "%.0f", node.signalStrength)) dBm")
                        }
                        .font(NETheme.mono(10))
                        .foregroundStyle(NETheme.textTertiary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(node.status.rawValue.uppercased())
                            .font(NETheme.mono(9))
                            .foregroundStyle(node.status == .online ? NETheme.severityLow : NETheme.severityMedium)
                        Text("\(node.edgeModules.count) modules")
                            .font(NETheme.mono(9))
                            .foregroundStyle(NETheme.textTertiary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassCard(cornerRadius: 10)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Presence Detection

    private var presenceView: some View {
        LazyVStack(spacing: 10) {
            HStack {
                Image(systemName: "person.wave.2")
                    .foregroundStyle(NETheme.accent)
                Text("Through-Wall Presence Detection")
                    .font(NETheme.subheading(14))
                    .foregroundStyle(NETheme.textPrimary)
                Spacer()
                Text("\(data.presenceDetections.count) active")
                    .font(NETheme.mono(11))
                    .foregroundStyle(NETheme.accent)
            }
            .padding(.horizontal)

            ForEach(data.presenceDetections) { detection in
                HStack(spacing: 12) {
                    Image(systemName: detection.motionState.icon)
                        .font(.title3)
                        .foregroundStyle(NETheme.accent)
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("\(detection.personCount) person\(detection.personCount > 1 ? "s" : "")")
                                .font(NETheme.subheading(13))
                            if detection.throughWall {
                                Text("THROUGH-WALL")
                                    .font(NETheme.mono(8))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(NETheme.accent.opacity(0.2))
                                    .foregroundStyle(NETheme.accent)
                                    .clipShape(Capsule())
                            }
                        }
                        Text("\(detection.motionState.rawValue.capitalized) • \(String(format: "%.1fm", detection.distanceMeters)) away")
                            .font(NETheme.caption())
                            .foregroundStyle(NETheme.textTertiary)
                    }

                    Spacer()

                    Text(String(format: "%.0f%%", detection.confidence * 100))
                        .font(NETheme.mono(12))
                        .foregroundStyle(detection.confidence > 0.85 ? NETheme.severityLow : NETheme.severityMedium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassCard(cornerRadius: 10)
                .padding(.horizontal)
            }

            if data.presenceDetections.isEmpty {
                ContentUnavailableView("No Detections", systemImage: "person.wave.2",
                                       description: Text("WiFi CSI presence sensing is loading..."))
            }
        }
        .padding(.vertical)
    }

    // MARK: - Vital Signs

    private var vitalsView: some View {
        LazyVStack(spacing: 10) {
            HStack {
                Image(systemName: "heart.text.clipboard")
                    .foregroundStyle(.pink)
                Text("Non-Contact Vital Signs (WiFi CSI)")
                    .font(NETheme.subheading(14))
                    .foregroundStyle(NETheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal)

            ForEach(data.wifiVitalSigns) { vital in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(String(format: "%.0f BPM", vital.breathingRate), systemImage: "lungs")
                            .font(NETheme.body())
                            .foregroundStyle(NETheme.accentSecondary)
                        Spacer()
                        Label(String(format: "%.0f BPM", vital.heartRate), systemImage: "heart.fill")
                            .font(NETheme.body())
                            .foregroundStyle(.pink)
                    }

                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Text("Breathing conf:")
                            Text(String(format: "%.0f%%", vital.breathingConfidence * 100))
                                .foregroundStyle(NETheme.accent)
                        }
                        HStack(spacing: 4) {
                            Text("HR conf:")
                            Text(String(format: "%.0f%%", vital.heartRateConfidence * 100))
                                .foregroundStyle(NETheme.accent)
                        }
                        Spacer()
                        Text(vital.signalQuality.rawValue.uppercased())
                            .font(NETheme.mono(9))
                            .foregroundStyle(Color(hex: vital.signalQuality.color))
                    }
                    .font(NETheme.mono(10))
                    .foregroundStyle(NETheme.textTertiary)
                }
                .padding()
                .glassCard(cornerRadius: 10)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Disaster Response

    private var disasterView: some View {
        LazyVStack(spacing: 10) {
            HStack {
                Image(systemName: "cross.case.fill")
                    .foregroundStyle(NETheme.severityCritical)
                Text("WiFi-MAT Disaster Response")
                    .font(NETheme.subheading(14))
                    .foregroundStyle(NETheme.textPrimary)
                Spacer()
                Text("\(data.disasterSurvivors.count) survivors")
                    .font(NETheme.mono(11))
                    .foregroundStyle(NETheme.severityHigh)
            }
            .padding(.horizontal)

            // Triage summary
            HStack(spacing: 12) {
                let green = data.disasterSurvivors.filter { $0.triageColor == .green }.count
                let yellow = data.disasterSurvivors.filter { $0.triageColor == .yellow }.count
                let red = data.disasterSurvivors.filter { $0.triageColor == .red }.count
                RFStatCard(title: "Minor", value: "\(green)", icon: "cross", color: NETheme.severityLow)
                RFStatCard(title: "Delayed", value: "\(yellow)", icon: "cross.circle", color: NETheme.severityMedium)
                RFStatCard(title: "Immediate", value: "\(red)", icon: "cross.case", color: NETheme.severityCritical)
            }
            .padding(.horizontal)

            ForEach(data.disasterSurvivors) { survivor in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(hex: survivor.triageColor.colorHex))
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Triage: \(survivor.triageColor.label)")
                            .font(NETheme.subheading(13))
                            .foregroundStyle(Color(hex: survivor.triageColor.colorHex))
                        HStack(spacing: 8) {
                            Label(survivor.breathingDetected ? "Breathing" : "No breathing",
                                  systemImage: survivor.breathingDetected ? "lungs.fill" : "lungs")
                            Label(survivor.movementDetected ? "Moving" : "Still",
                                  systemImage: survivor.movementDetected ? "figure.walk" : "figure.stand")
                            if survivor.estimatedDepthMeters > 0 {
                                Text(String(format: "%.1fm deep", survivor.estimatedDepthMeters))
                            }
                        }
                        .font(NETheme.caption())
                        .foregroundStyle(NETheme.textTertiary)
                    }

                    Spacer()

                    Text(String(format: "%.0f%%", survivor.confidenceScore * 100))
                        .font(NETheme.mono(12))
                        .foregroundStyle(NETheme.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassCard(cornerRadius: 10)
                .padding(.horizontal)
            }

            if data.disasterSurvivors.isEmpty {
                ContentUnavailableView("No Active Disasters", systemImage: "checkmark.shield",
                                       description: Text("WiFi-MAT activates during earthquake/disaster events"))
            }
        }
        .padding(.vertical)
    }

    // MARK: - RF Interference

    private var interferenceView: some View {
        LazyVStack(spacing: 10) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right.slash")
                    .foregroundStyle(NETheme.severityHigh)
                Text("RF Interference & Jamming Zones")
                    .font(NETheme.subheading(14))
                    .foregroundStyle(NETheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal)

            ForEach(data.rfInterferenceZones) { zone in
                HStack(spacing: 12) {
                    Image(systemName: zone.interferenceType.icon)
                        .font(.title3)
                        .foregroundStyle(NETheme.severityHigh)
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(zone.source)
                            .font(NETheme.subheading(13))
                            .foregroundStyle(NETheme.textPrimary)
                        HStack(spacing: 8) {
                            Text(zone.interferenceType.rawValue.uppercased())
                                .font(NETheme.mono(9))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(NETheme.severityHigh.opacity(0.2))
                                .foregroundStyle(NETheme.severityHigh)
                                .clipShape(Capsule())
                            Text(String(format: "%.1f GHz", zone.affectedFrequencyGHz))
                            Text(String(format: "%.0f km radius", zone.radiusKm))
                        }
                        .font(NETheme.mono(10))
                        .foregroundStyle(NETheme.textTertiary)
                    }

                    Spacer()

                    // Severity gauge
                    ZStack {
                        Circle()
                            .stroke(NETheme.surfaceOverlay, lineWidth: 3)
                            .frame(width: 32, height: 32)
                        Circle()
                            .trim(from: 0, to: zone.severity)
                            .stroke(zone.severity > 0.7 ? NETheme.severityCritical : NETheme.severityMedium,
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 32, height: 32)
                            .rotationEffect(.degrees(-90))
                        Text(String(format: "%.0f", zone.severity * 100))
                            .font(NETheme.mono(8))
                            .foregroundStyle(NETheme.textSecondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassCard(cornerRadius: 10)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Reusable RF Stat Card

struct RFStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(NETheme.heading(18))
                .foregroundStyle(NETheme.textPrimary)
            Text(title)
                .font(NETheme.caption(10))
                .foregroundStyle(NETheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .glassCard(cornerRadius: 10)
    }
}
