import SwiftUI
import Charts

struct ReactorView: View {
    @State private var selectedParameters: SynthesisParameters
    @State private var showingParameterHistory = false
    @State private var realTimeMode = false
    @State private var parameterHistory: [ParameterSnapshot] = []
    @State private var timer: Timer?

    init(parameters: SynthesisParameters = SynthesisParameters(gemstoneType: .redBeryl)) {
        self._selectedParameters = State(initialValue: parameters)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Reactor Visualization
                    ReactorVisualization(parameters: selectedParameters)
                        .frame(height: 300)
                        .padding()
                        .background(Color.secondaryGroupedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    // MARK: - Real-time Monitoring
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label("Real-time Monitoring", systemImage: "waveform.badge.plus")
                                .font(.headline)
                            Spacer()
                            Toggle("Live", isOn: $realTimeMode)
                                .toggleStyle(.button)
                                .tint(.green)
                        }

                        if realTimeMode {
                            RealTimeMetrics(parameters: selectedParameters)
                        } else {
                            Text("Enable live mode to monitor reactor conditions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.secondaryGroupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // MARK: - Parameter Charts
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Parameter Trends", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.headline)

                        if !parameterHistory.isEmpty {
                            ParameterTrendsChart(history: parameterHistory)
                                .frame(height: 200)
                        } else {
                            ContentUnavailableView(
                                "No Data Yet",
                                systemImage: "chart.line.downtrend.xyaxis",
                                description: Text("Enable real-time mode to start collecting data")
                            )
                            .frame(height: 200)
                        }
                    }
                    .padding()
                    .background(Color.secondaryGroupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // MARK: - Reactor Stats
                    ReactorStatsGrid(parameters: selectedParameters)
                }
                .padding()
            }
            .navigationTitle("Digital Twin")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("History", systemImage: "clock.arrow.circlepath") {
                        showingParameterHistory = true
                    }
                }
            }
            .onAppear {
                startMonitoring()
            }
            .onDisappear {
                stopMonitoring()
            }
            .sheet(isPresented: $showingParameterHistory) {
                ParameterHistoryView(history: parameterHistory)
            }
        }
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if realTimeMode {
                captureSnapshot()
            }
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func captureSnapshot() {
        let snapshot = ParameterSnapshot(
            timestamp: Date(),
            temperature: selectedParameters.temperature + Double.random(in: -2...2),
            pressure: selectedParameters.pressure + Double.random(in: -5...5),
            pH: selectedParameters.pH + Double.random(in: -0.1...0.1)
        )
        parameterHistory.append(snapshot)

        // Keep only last 60 snapshots
        if parameterHistory.count > 60 {
            parameterHistory.removeFirst()
        }
    }
}

// MARK: - Parameter Snapshot

struct ParameterSnapshot: Identifiable {
    let id = UUID()
    let timestamp: Date
    let temperature: Double
    let pressure: Double
    let pH: Double
}

// MARK: - Reactor Visualization

struct ReactorVisualization: View {
    let parameters: SynthesisParameters
    @State private var animationPhase: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Reactor vessel
                ReactorVessel(
                    temperature: parameters.temperature,
                    pressure: parameters.pressure,
                    gemstoneType: parameters.gemstoneType
                )
                .frame(width: geometry.size.width * 0.6, height: geometry.size.height * 0.8)

                // Parameter indicators
                VStack {
                    HStack(spacing: 20) {
                        ParameterIndicator(
                            icon: "thermometer",
                            value: "\(Int(parameters.temperature))°C",
                            color: temperatureColor(parameters.temperature, for: parameters.gemstoneType)
                        )
                        ParameterIndicator(
                            icon: "gauge.with.needle",
                            value: "\(Int(parameters.pressure)) MPa",
                            color: pressureColor(parameters.pressure, for: parameters.gemstoneType)
                        )
                        ParameterIndicator(
                            icon: "drop.fill",
                            value: String(format: "pH %.1f", parameters.pH),
                            color: pHColor(parameters.pH, for: parameters.gemstoneType)
                        )
                    }
                    .padding(.top)
                    Spacer()
                }
            }
        }
    }

    private func temperatureColor(_ temp: Double, for gemstone: GemstoneType) -> Color {
        let range = gemstone.defaultTemperatureRange
        let normalized = (temp - range.lowerBound) / (range.upperBound - range.lowerBound)
        if normalized < 0.3 {
            return .blue
        } else if normalized < 0.7 {
            return .green
        } else {
            return .red
        }
    }

    private func pressureColor(_ pressure: Double, for gemstone: GemstoneType) -> Color {
        let range = gemstone.defaultPressureRange
        let normalized = (pressure - range.lowerBound) / (range.upperBound - range.lowerBound)
        if normalized < 0.3 {
            return .blue
        } else if normalized < 0.7 {
            return .green
        } else {
            return .orange
        }
    }

    private func pHColor(_ pH: Double, for gemstone: GemstoneType) -> Color {
        let range = gemstone.defaultPHRange
        if pH < range.lowerBound {
            return .orange
        } else if pH > range.upperBound {
            return .purple
        } else {
            return .green
        }
    }
}

// MARK: - Reactor Vessel

struct ReactorVessel: View {
    let temperature: Double
    let pressure: Double
    let gemstoneType: GemstoneType
    @State private var bubbleAnimation = false

    var body: some View {
        ZStack {
            // Vessel body
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray, lineWidth: 2)
                )

            // Fluid inside
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Spacer()

                    // Fluid with animated bubbles
                    ZStack {
                        // Base fluid
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: fluidColors(for: gemstoneType),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: geometry.size.height * 0.7)

                        // Animated bubbles
                        ForEach(0..<5, id: \.self) { index in
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 10, height: 10)
                                .offset(
                                    x: CGFloat.random(in: -geometry.size.width/3...geometry.size.width/3),
                                    y: bubbleAnimation ? -geometry.size.height * 0.7 : 0
                                )
                                .animation(
                                    .easeInOut(duration: Double.random(in: 2...4))
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 0.3),
                                    value: bubbleAnimation
                                )
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding(8)

            // Crystal growing in center
            Image(systemName: "rhombus.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .foregroundStyle(gemstoneColor(for: gemstoneType))
                .rotationEffect(.degrees(45))
                .shadow(color: gemstoneColor(for: gemstoneType).opacity(0.5), radius: 10)
        }
        .onAppear {
            bubbleAnimation = true
        }
    }

    private func fluidColors(for gemstone: GemstoneType) -> [Color] {
        switch gemstone {
        case .redBeryl:
            return [Color.red.opacity(0.2), Color.red.opacity(0.4)]
        case .alexandrite:
            return [Color.green.opacity(0.2), Color.purple.opacity(0.3)]
        case .tanzanite:
            return [Color.blue.opacity(0.2), Color.indigo.opacity(0.3)]
        case .paraibaTourmaline:
            return [Color.cyan.opacity(0.2), Color.teal.opacity(0.3)]
        }
    }

    private func gemstoneColor(for gemstone: GemstoneType) -> Color {
        switch gemstone {
        case .redBeryl:
            return .red
        case .alexandrite:
            return .purple
        case .tanzanite:
            return .indigo
        case .paraibaTourmaline:
            return .cyan
        }
    }
}

// MARK: - Parameter Indicator

struct ParameterIndicator: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(width: 80)
        .padding(8)
        .background(Color.tertiaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Real-time Metrics

struct RealTimeMetrics: View {
    let parameters: SynthesisParameters
    @State private var growthRate: Double = 0
    @State private var qualityIndex: Double = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                MetricCard(
                    title: "Growth Rate",
                    value: String(format: "%.3f mm/h", growthRate),
                    trend: .up
                )
                MetricCard(
                    title: "Quality Index",
                    value: String(format: "%.2f", qualityIndex),
                    trend: .stable
                )
            }

            HStack {
                MetricCard(
                    title: "Defect Rate",
                    value: String(format: "%.1f/mm³", 50 - qualityIndex * 20),
                    trend: .down
                )
                MetricCard(
                    title: "Est. Yield",
                    value: String(format: "%.2f g", growthRate * parameters.duration * 0.01),
                    trend: .up
                )
            }
        }
        .onAppear {
            updateMetrics()
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateMetrics()
        }
    }

    private func updateMetrics() {
        // Simulate real-time metrics based on parameters
        let tempFactor = parameters.temperature / 600
        let pressureFactor = parameters.pressure / 250
        let pHFactor = 1.0 - abs(parameters.pH - 7.0) / 2.0

        growthRate = 0.01 * tempFactor * pressureFactor + Double.random(in: -0.002...0.002)
        qualityIndex = min(1.0, pHFactor * tempFactor * 0.8 + Double.random(in: -0.05...0.05))
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let title: String
    let value: String
    let trend: Trend

    enum Trend {
        case up, down, stable

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "minus"
            }
        }

        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .stable: return .orange
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundStyle(trend.color)
            }
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.tertiaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Parameter Trends Chart

struct ParameterTrendsChart: View {
    let history: [ParameterSnapshot]

    var body: some View {
        Chart(history) { snapshot in
            LineMark(
                x: .value("Time", snapshot.timestamp),
                y: .value("Temperature", snapshot.temperature),
                series: .value("Parameter", "Temperature")
            )
            .foregroundStyle(.red)
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Time", snapshot.timestamp),
                y: .value("Pressure", snapshot.pressure / 10), // Scaled for visibility
                series: .value("Parameter", "Pressure")
            )
            .foregroundStyle(.blue)
            .interpolationMethod(.catmullRom)
        }
        .chartLegend(position: .bottom)
    }
}

// MARK: - Reactor Stats Grid

struct ReactorStatsGrid: View {
    let parameters: SynthesisParameters

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Reactor Statistics", systemImage: "info.circle")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                GridRow {
                    StatItem(title: "Reactor Volume", value: "500 mL")
                    StatItem(title: "Max Pressure", value: "500 MPa")
                }
                GridRow {
                    StatItem(title: "Heating Power", value: "2.5 kW")
                    StatItem(title: "Temperature Range", value: "25-900°C")
                }
                GridRow {
                    StatItem(title: "Seed Crystal", value: String(format: "%.1f mm", parameters.seedCrystalSize))
                    StatItem(title: "Solution", value: String(format: "%.2f mol/L", parameters.nutrientConcentration))
                }
            }
        }
        .padding()
        .background(Color.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Parameter History View

struct ParameterHistoryView: View {
    let history: [ParameterSnapshot]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if !history.isEmpty {
                        ParameterTrendsChart(history: history)
                            .frame(height: 300)
                            .padding()
                    } else {
                        ContentUnavailableView(
                            "No History",
                            systemImage: "clock.arrow.circlepath",
                            description: Text("Parameter history will appear here")
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Parameter History")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ReactorView()
}