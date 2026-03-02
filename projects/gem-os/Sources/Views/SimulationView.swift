import SwiftUI
import Charts

struct SimulationView: View {
    @Environment(StoreManager.self) private var storeManager
    @State private var viewModel = SimulationViewModel()
    @State private var selectedResult: SimulationResult?
    @State private var showingExportOptions = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Parameters Section
                    ParametersCard(viewModel: viewModel)

                    // MARK: - Run Simulation
                    SimulationControlsCard(viewModel: viewModel)

                    // MARK: - Results
                    if !viewModel.results.isEmpty {
                        ResultsSection(
                            results: viewModel.results,
                            selectedResult: $selectedResult,
                            showingExportOptions: $showingExportOptions
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Simulation")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Load Recipe", systemImage: "book") {
                            // Navigation handled by ContentView
                        }
                        Button("Optimize Parameters", systemImage: "sparkles") {
                            // Navigation handled by ContentView
                        }
                        Divider()
                        Button("Reset Parameters", systemImage: "arrow.counterclockwise") {
                            viewModel.resetParameters()
                        }
                        if !viewModel.results.isEmpty {
                            Button("Clear Results", systemImage: "trash") {
                                viewModel.clearResults()
                            }
                        }
                    } label: {
                        Label("Options", systemImage: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingExportOptions) {
                if let result = selectedResult {
                    ExportView(result: result)
                }
            }
        }
    }
}

// MARK: - Parameters Card

struct ParametersCard: View {
    @Bindable var viewModel: SimulationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Parameters", systemImage: "slider.horizontal.3")
                .font(.headline)

            // Gemstone Type
            Picker("Gemstone", selection: $viewModel.parameters.gemstoneType) {
                ForEach(GemstoneType.allCases, id: \.self) { type in
                    // Only show Red Beryl and Alexandrite for MVP
                    if type == .redBeryl || type == .alexandrite {
                        Text(type.displayName).tag(type)
                    }
                }
            }
            .pickerStyle(.segmented)

            // Temperature
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Temperature")
                    Spacer()
                    Text("\(Int(viewModel.parameters.temperature))°C")
                        .foregroundStyle(.secondary)
                }
                Slider(
                    value: $viewModel.parameters.temperature,
                    in: viewModel.parameters.gemstoneType.defaultTemperatureRange,
                    step: 5
                )
            }

            // Pressure
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Pressure")
                    Spacer()
                    Text("\(Int(viewModel.parameters.pressure)) MPa")
                        .foregroundStyle(.secondary)
                }
                Slider(
                    value: $viewModel.parameters.pressure,
                    in: viewModel.parameters.gemstoneType.defaultPressureRange,
                    step: 5
                )
            }

            // pH
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("pH")
                    Spacer()
                    Text(String(format: "%.1f", viewModel.parameters.pH))
                        .foregroundStyle(.secondary)
                }
                Slider(
                    value: $viewModel.parameters.pH,
                    in: viewModel.parameters.gemstoneType.defaultPHRange,
                    step: 0.1
                )
            }

            // Duration
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Duration")
                    Spacer()
                    Text("\(Int(viewModel.parameters.duration)) hours")
                        .foregroundStyle(.secondary)
                }
                Slider(
                    value: $viewModel.parameters.duration,
                    in: 24...480,
                    step: 24
                )
            }

            // Advanced Parameters
            DisclosureGroup("Advanced") {
                VStack(alignment: .leading, spacing: 12) {
                    // Nutrient Concentration
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Nutrient Concentration")
                            Spacer()
                            Text(String(format: "%.2f mol/L", viewModel.parameters.nutrientConcentration))
                                .foregroundStyle(.secondary)
                        }
                        Slider(
                            value: $viewModel.parameters.nutrientConcentration,
                            in: 0.1...1.0,
                            step: 0.05
                        )
                    }

                    // Seed Crystal Size
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Seed Crystal Size")
                            Spacer()
                            Text(String(format: "%.1f mm", viewModel.parameters.seedCrystalSize))
                                .foregroundStyle(.secondary)
                        }
                        Slider(
                            value: $viewModel.parameters.seedCrystalSize,
                            in: 0.1...5.0,
                            step: 0.1
                        )
                    }

                    // Cooling Rate
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Cooling Rate")
                            Spacer()
                            Text(String(format: "%.1f°C/hour", viewModel.parameters.coolingRate))
                                .foregroundStyle(.secondary)
                        }
                        Slider(
                            value: $viewModel.parameters.coolingRate,
                            in: 0.5...10.0,
                            step: 0.5
                        )
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Simulation Controls Card

struct SimulationControlsCard: View {
    @Bindable var viewModel: SimulationViewModel
    @Environment(StoreManager.self) private var storeManager

    var body: some View {
        VStack(spacing: 16) {
            // Iterations
            VStack(alignment: .leading, spacing: 8) {
                Label("Monte Carlo Iterations", systemImage: "chart.scatter")
                    .font(.headline)

                Picker("Iterations", selection: $viewModel.iterations) {
                    Text("10,000").tag(10_000)
                    Text("25,000").tag(25_000)
                    Text("50,000").tag(50_000)
                    Text("100,000").tag(100_000)
                }
                .pickerStyle(.segmented)
                .disabled(!storeManager.isSubscribed || viewModel.isRunning)

                if !storeManager.isSubscribed {
                    Label("Premium subscription required for more iterations", systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Run Button
            Button(action: {
                Task {
                    await viewModel.runSimulation()
                }
            }) {
                HStack {
                    if viewModel.isRunning {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "play.fill")
                    }
                    Text(viewModel.isRunning ? "Running..." : "Run Simulation")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isRunning ? Color.secondary : Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.isRunning)

            // Progress
            if viewModel.isRunning {
                VStack(spacing: 4) {
                    ProgressView(value: viewModel.progress)
                    Text("\(Int(viewModel.progress * 100))% Complete")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Error
            if let error = viewModel.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(Color.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Results Section

struct ResultsSection: View {
    let results: [SimulationResult]
    @Binding var selectedResult: SimulationResult?
    @Binding var showingExportOptions: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Results", systemImage: "chart.bar")
                    .font(.headline)
                Spacer()
                if !results.isEmpty {
                    Button("Export", systemImage: "square.and.arrow.up") {
                        selectedResult = results.first
                        showingExportOptions = true
                    }
                }
            }

            ForEach(results) { result in
                ResultCard(result: result) {
                    selectedResult = result
                    showingExportOptions = true
                }
            }
        }
    }
}

// MARK: - Result Card

struct ResultCard: View {
    let result: SimulationResult
    let onExport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.parameters.gemstoneType.displayName)
                        .font(.headline)
                    Text(result.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Export", systemImage: "square.and.arrow.up") {
                    onExport()
                }
                .buttonStyle(.bordered)
            }

            Divider()

            // Key Metrics
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 8) {
                GridRow {
                    MetricView(title: "Yield", value: String(format: "%.2f g", result.crystalYield))
                    MetricView(title: "Size", value: String(format: "%.1f mm", result.averageSize))
                }
                GridRow {
                    MetricView(title: "Quality", value: String(format: "%.1f%%", result.overallQuality * 100))
                    MetricView(title: "Success", value: String(format: "%.1f%%", result.successProbability * 100))
                }
                GridRow {
                    MetricView(title: "Clarity", value: String(format: "%.2f", result.clarity))
                    MetricView(title: "Color", value: String(format: "%.2f", result.colorSaturation))
                }
            }

            // Quality Chart
            QualityChart(result: result)
                .frame(height: 120)
        }
        .padding()
        .background(Color.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Metric View

struct MetricView: View {
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
    }
}

// MARK: - Quality Chart

struct QualityChart: View {
    let result: SimulationResult

    var body: some View {
        Chart {
            BarMark(
                x: .value("Metric", "Clarity"),
                y: .value("Value", result.clarity)
            )
            .foregroundStyle(.blue)

            BarMark(
                x: .value("Metric", "Color"),
                y: .value("Value", result.colorSaturation)
            )
            .foregroundStyle(.purple)

            BarMark(
                x: .value("Metric", "Quality"),
                y: .value("Value", result.overallQuality)
            )
            .foregroundStyle(.green)

            BarMark(
                x: .value("Metric", "Success"),
                y: .value("Value", result.successProbability)
            )
            .foregroundStyle(.orange)
        }
        .chartYScale(domain: 0...1)
        .chartYAxis {
            AxisMarks(values: [0, 0.5, 1]) { value in
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("\(Int(v * 100))%")
                    }
                }
                AxisGridLine()
            }
        }
    }
}

#Preview {
    SimulationView()
        .environment(StoreManager())
}