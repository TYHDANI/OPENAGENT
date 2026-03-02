import SwiftUI
import Charts

struct OptimizationView: View {
    @State private var viewModel = OptimizationViewModel()
    @State private var showingParameterComparison = false
    @Environment(StoreManager.self) private var storeManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Goal Selection
                    GoalSelectionCard(viewModel: viewModel)

                    // MARK: - Current Parameters
                    CurrentParametersCard(parameters: viewModel.parameters)

                    // MARK: - Optimize Button
                    OptimizeButton(viewModel: viewModel)

                    // MARK: - Optimization Results
                    if let result = viewModel.optimizationResult {
                        OptimizationResultsCard(
                            result: result,
                            onApply: {
                                viewModel.applyOptimizedParameters()
                            },
                            onCompare: {
                                showingParameterComparison = true
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Optimization")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Reset", systemImage: "arrow.counterclockwise") {
                        viewModel.resetParameters()
                    }
                }
            }
            .sheet(isPresented: $showingParameterComparison) {
                if let result = viewModel.optimizationResult {
                    ParameterComparisonView(
                        original: result.originalParameters,
                        optimized: result.optimizedParameters
                    )
                }
            }
        }
    }

    // Update parameters from external source
    func updateParameters(_ parameters: SynthesisParameters) {
        viewModel.updateParameters(parameters)
    }
}

// MARK: - Goal Selection Card

struct GoalSelectionCard: View {
    @Bindable var viewModel: OptimizationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Optimization Goal", systemImage: "target")
                .font(.headline)

            VStack(spacing: 12) {
                ForEach([
                    OptimizationService.OptimizationGoal.maximizeYield,
                    .maximizeQuality,
                    .minimizeTime,
                    .balanced
                ], id: \.self) { goal in
                    GoalOption(
                        goal: goal,
                        isSelected: viewModel.selectedGoal == goal,
                        action: { viewModel.selectedGoal = goal }
                    )
                }
            }

            Text(goalDescription(for: viewModel.selectedGoal))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
        .padding()
        .background(Color.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func goalDescription(for goal: OptimizationService.OptimizationGoal) -> String {
        switch goal {
        case .maximizeYield:
            return "Optimize parameters to produce the maximum crystal yield, potentially at the expense of quality."
        case .maximizeQuality:
            return "Focus on producing the highest quality crystals with minimal defects and maximum clarity."
        case .minimizeTime:
            return "Reduce synthesis duration while maintaining acceptable yield and quality."
        case .balanced:
            return "Find the optimal balance between yield, quality, and time efficiency."
        }
    }
}

// MARK: - Goal Option

struct GoalOption: View {
    let goal: OptimizationService.OptimizationGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.displayName)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)

                    Text(goalIcon(for: goal))
                        .font(.caption)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.tertiaryGroupedBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func goalIcon(for goal: OptimizationService.OptimizationGoal) -> String {
        switch goal {
        case .maximizeYield:
            return "📈 Focus on quantity"
        case .maximizeQuality:
            return "💎 Focus on perfection"
        case .minimizeTime:
            return "⚡ Focus on speed"
        case .balanced:
            return "⚖️ Balance all factors"
        }
    }
}

// MARK: - Current Parameters Card

struct CurrentParametersCard: View {
    let parameters: SynthesisParameters

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Current Parameters", systemImage: "slider.horizontal.3")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 12) {
                GridRow {
                    ParameterValue(label: "Temperature", value: "\(Int(parameters.temperature))°C")
                    ParameterValue(label: "Pressure", value: "\(Int(parameters.pressure)) MPa")
                }
                GridRow {
                    ParameterValue(label: "pH", value: String(format: "%.1f", parameters.pH))
                    ParameterValue(label: "Duration", value: "\(Int(parameters.duration))h")
                }
                GridRow {
                    ParameterValue(label: "Nutrient", value: String(format: "%.2f mol/L", parameters.nutrientConcentration))
                    ParameterValue(label: "Cooling", value: String(format: "%.1f°C/h", parameters.coolingRate))
                }
            }

            Label("Gemstone: \(parameters.gemstoneType.displayName)", systemImage: "rhombus.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Parameter Value

struct ParameterValue: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Optimize Button

struct OptimizeButton: View {
    @Bindable var viewModel: OptimizationViewModel
    @Environment(StoreManager.self) private var storeManager

    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    await viewModel.optimizeParameters()
                }
            }) {
                HStack {
                    if viewModel.isOptimizing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(viewModel.isOptimizing ? "Optimizing..." : "Optimize Parameters")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isOptimizing ? Color.secondary : Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.isOptimizing || !storeManager.isSubscribed)

            if !storeManager.isSubscribed {
                Label("Premium subscription required", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let error = viewModel.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}

// MARK: - Optimization Results Card

struct OptimizationResultsCard: View {
    let result: OptimizationService.OptimizationResult
    let onApply: () -> Void
    let onCompare: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Label("Optimization Results", systemImage: "checkmark.seal")
                    .font(.headline)
                Spacer()
                Text("+\(Int(result.expectedImprovement))%")
                    .font(.headline)
                    .foregroundStyle(.green)
            }

            // Recommendations
            VStack(alignment: .leading, spacing: 12) {
                ForEach(result.recommendations, id: \.parameter) { recommendation in
                    RecommendationRow(recommendation: recommendation)
                }
            }

            // Actions
            HStack(spacing: 12) {
                Button(action: onCompare) {
                    Label("Compare", systemImage: "chart.bar.doc.horizontal")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: onApply) {
                    Label("Apply Changes", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Recommendation Row

struct RecommendationRow: View {
    let recommendation: OptimizationService.OptimizationResult.Recommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recommendation.parameter)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                ImpactBadge(impact: recommendation.impact)
            }

            HStack(spacing: 8) {
                Text(recommendation.currentValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.tertiaryGroupedBackground)
                    .clipShape(Capsule())

                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(recommendation.recommendedValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.2))
                    .clipShape(Capsule())
            }

            Text(recommendation.reason)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.tertiaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Impact Badge

struct ImpactBadge: View {
    let impact: OptimizationService.OptimizationResult.Recommendation.Impact

    private var badgeColor: Color {
        switch impact {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        }
    }

    var body: some View {
        Text(impact.rawValue)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.2))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
    }
}

// MARK: - Parameter Comparison View

struct ParameterComparisonView: View {
    @Environment(\.dismiss) private var dismiss
    let original: SynthesisParameters
    let optimized: SynthesisParameters

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Comparison Chart
                    ComparisonChart(original: original, optimized: optimized)
                        .frame(height: 300)
                        .padding()
                        .background(Color.secondaryGroupedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Detailed Comparison
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Detailed Comparison", systemImage: "list.bullet")
                            .font(.headline)

                        ComparisonTable(original: original, optimized: optimized)
                    }
                    .padding()
                    .background(Color.secondaryGroupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("Parameter Comparison")
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

// MARK: - Comparison Chart

struct ComparisonChart: View {
    let original: SynthesisParameters
    let optimized: SynthesisParameters

    private struct ChartEntry: Identifiable {
        let id = UUID()
        let parameter: String
        let type: String
        let value: Double
    }

    private var chartData: [ChartEntry] {
        [
            ChartEntry(parameter: "Temp", type: "Original", value: original.temperature / 10),
            ChartEntry(parameter: "Temp", type: "Optimized", value: optimized.temperature / 10),
            ChartEntry(parameter: "Pressure", type: "Original", value: original.pressure / 10),
            ChartEntry(parameter: "Pressure", type: "Optimized", value: optimized.pressure / 10),
            ChartEntry(parameter: "pH", type: "Original", value: original.pH),
            ChartEntry(parameter: "pH", type: "Optimized", value: optimized.pH),
            ChartEntry(parameter: "Duration", type: "Original", value: original.duration / 24),
            ChartEntry(parameter: "Duration", type: "Optimized", value: optimized.duration / 24),
        ]
    }

    var body: some View {
        Chart(chartData) { entry in
            BarMark(
                x: .value("Parameter", entry.parameter),
                y: .value("Value", entry.value)
            )
            .foregroundStyle(by: .value("Type", entry.type))
            .position(by: .value("Type", entry.type))
        }
        .chartForegroundStyleScale(["Original": Color.gray.opacity(0.6), "Optimized": Color.accentColor])
        .chartLegend(position: .top)
    }
}

// MARK: - Comparison Table

struct ComparisonTable: View {
    let original: SynthesisParameters
    let optimized: SynthesisParameters

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Parameter")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Original")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(width: 80)
                Text("Optimized")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(width: 80)
                Text("Change")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(width: 60)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Rows
            ComparisonRow(
                parameter: "Temperature",
                original: "\(Int(original.temperature))°C",
                optimized: "\(Int(optimized.temperature))°C",
                change: percentageChange(from: original.temperature, to: optimized.temperature)
            )

            ComparisonRow(
                parameter: "Pressure",
                original: "\(Int(original.pressure)) MPa",
                optimized: "\(Int(optimized.pressure)) MPa",
                change: percentageChange(from: original.pressure, to: optimized.pressure)
            )

            ComparisonRow(
                parameter: "pH",
                original: String(format: "%.1f", original.pH),
                optimized: String(format: "%.1f", optimized.pH),
                change: percentageChange(from: original.pH, to: optimized.pH)
            )

            ComparisonRow(
                parameter: "Duration",
                original: "\(Int(original.duration))h",
                optimized: "\(Int(optimized.duration))h",
                change: percentageChange(from: original.duration, to: optimized.duration)
            )

            ComparisonRow(
                parameter: "Nutrient Conc.",
                original: String(format: "%.2f", original.nutrientConcentration),
                optimized: String(format: "%.2f", optimized.nutrientConcentration),
                change: percentageChange(from: original.nutrientConcentration, to: optimized.nutrientConcentration)
            )

            ComparisonRow(
                parameter: "Cooling Rate",
                original: String(format: "%.1f°C/h", original.coolingRate),
                optimized: String(format: "%.1f°C/h", optimized.coolingRate),
                change: percentageChange(from: original.coolingRate, to: optimized.coolingRate)
            )
        }
        .background(Color.tertiaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func percentageChange(from original: Double, to optimized: Double) -> Double {
        guard original != 0 else { return 0 }
        return ((optimized - original) / original) * 100
    }
}

// MARK: - Comparison Row

struct ComparisonRow: View {
    let parameter: String
    let original: String
    let optimized: String
    let change: Double

    var body: some View {
        HStack {
            Text(parameter)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(original)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 80)
            Text(optimized)
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 80)
            Text(change == 0 ? "-" : String(format: "%+.0f%%", change))
                .font(.caption)
                .foregroundStyle(changeColor(change))
                .frame(width: 60)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func changeColor(_ change: Double) -> Color {
        if change > 0 {
            return .green
        } else if change < 0 {
            return .orange
        } else {
            return .secondary
        }
    }
}

#Preview {
    OptimizationView()
        .environment(StoreManager())
}