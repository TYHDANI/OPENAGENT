import Foundation
import Observation

/// ViewModel for parameter optimization
@MainActor
@Observable
final class OptimizationViewModel {

    // MARK: - State

    /// Current synthesis parameters
    var parameters: SynthesisParameters

    /// Selected optimization goal
    var selectedGoal: OptimizationService.OptimizationGoal = .balanced

    /// Current optimization result
    private(set) var optimizationResult: OptimizationService.OptimizationResult?

    /// Whether optimization is in progress
    private(set) var isOptimizing = false

    /// Error message if optimization fails
    private(set) var errorMessage: String?

    // MARK: - Initialization

    init(gemstoneType: GemstoneType = .redBeryl) {
        self.parameters = SynthesisParameters(gemstoneType: gemstoneType)
    }

    // MARK: - Actions

    /// Optimize parameters based on selected goal
    func optimizeParameters() async {
        guard !isOptimizing else { return }

        isOptimizing = true
        errorMessage = nil

        let result = await OptimizationService.shared.optimizeParameters(
            current: parameters,
            goal: selectedGoal
        )

        optimizationResult = result

        isOptimizing = false
    }

    /// Apply the optimized parameters
    func applyOptimizedParameters() {
        guard let result = optimizationResult else { return }
        parameters = result.optimizedParameters
    }

    /// Reset parameters to defaults
    func resetParameters() {
        parameters = SynthesisParameters(gemstoneType: parameters.gemstoneType)
        optimizationResult = nil
    }

    /// Update parameters from another source
    func updateParameters(_ newParameters: SynthesisParameters) {
        parameters = newParameters
        optimizationResult = nil
    }
}