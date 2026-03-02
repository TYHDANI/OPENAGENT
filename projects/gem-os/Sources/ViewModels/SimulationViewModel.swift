import Foundation
import Observation

/// ViewModel for running Monte Carlo simulations
@MainActor
@Observable
final class SimulationViewModel {

    // MARK: - State

    /// Current synthesis parameters being edited
    var parameters: SynthesisParameters

    /// Whether a simulation is currently running
    private(set) var isRunning = false

    /// Progress of the current simulation (0-1)
    private(set) var progress: Double = 0

    /// Results from completed simulations
    private(set) var results: [SimulationResult] = []

    /// Error message if simulation fails
    private(set) var errorMessage: String?

    /// Number of iterations for Monte Carlo simulation
    var iterations: Int = 10_000 {
        didSet {
            iterations = max(1000, min(100_000, iterations))
        }
    }

    // MARK: - Initialization

    init(gemstoneType: GemstoneType = .redBeryl) {
        self.parameters = SynthesisParameters(gemstoneType: gemstoneType)
    }

    // MARK: - Actions

    /// Run a simulation with current parameters
    func runSimulation() async {
        guard !isRunning else { return }

        isRunning = true
        errorMessage = nil
        progress = 0

        let result = await MonteCarloEngine.shared.runSimulation(
            parameters: parameters,
            iterations: iterations,
            progressHandler: { [weak self] progress in
                self?.progress = progress
            }
        )

        results.insert(result, at: 0)

        // Keep only last 10 results
        if results.count > 10 {
            results = Array(results.prefix(10))
        }

        isRunning = false
        progress = 0
    }

    /// Clear all simulation results
    func clearResults() {
        results.removeAll()
    }

    /// Load a recipe's parameters
    func loadRecipe(_ recipe: Recipe) {
        parameters = recipe.parameters
    }

    /// Reset parameters to defaults for current gemstone type
    func resetParameters() {
        parameters = SynthesisParameters(gemstoneType: parameters.gemstoneType)
    }
}