import Foundation

/// Monte Carlo simulation engine for hydrothermal gemstone synthesis
final class MonteCarloEngine {
    static let shared = MonteCarloEngine()

    private init() {}

    /// Run Monte Carlo simulation with given parameters
    /// - Parameters:
    ///   - parameters: Synthesis parameters to simulate
    ///   - iterations: Number of Monte Carlo iterations (default: 10,000)
    ///   - progressHandler: Optional callback for progress updates
    /// - Returns: Simulation result with statistical analysis
    func runSimulation(
        parameters: SynthesisParameters,
        iterations: Int = 10_000,
        progressHandler: ((Double) -> Void)? = nil
    ) async -> SimulationResult {
        let startTime = Date()

        // Statistical accumulators
        var totalYield: Double = 0
        var totalSize: Double = 0
        var totalClarity: Double = 0
        var totalColorSaturation: Double = 0
        var totalDefects: Double = 0
        var successCount: Int = 0

        // Run Monte Carlo iterations
        for i in 0..<iterations {
            // Report progress
            if i % 100 == 0 {
                let progress = Double(i) / Double(iterations)
                await MainActor.run {
                    progressHandler?(progress)
                }
            }

            // Simulate single crystal growth
            let result = simulateSingleRun(parameters: parameters)

            // Accumulate results
            totalYield += result.yield
            totalSize += result.size
            totalClarity += result.clarity
            totalColorSaturation += result.colorSaturation
            totalDefects += result.defects

            if result.success {
                successCount += 1
            }
        }

        // Calculate averages
        let iterationsDouble = Double(iterations)
        let averageYield = totalYield / iterationsDouble
        let averageSize = totalSize / iterationsDouble
        let averageClarity = totalClarity / iterationsDouble
        let averageColorSaturation = totalColorSaturation / iterationsDouble
        let averageDefects = totalDefects / iterationsDouble
        let successProbability = Double(successCount) / iterationsDouble

        let simulationTime = Date().timeIntervalSince(startTime)

        return SimulationResult(
            id: UUID(),
            timestamp: Date(),
            parameters: parameters,
            iterations: iterations,
            crystalYield: averageYield,
            averageSize: averageSize,
            clarity: averageClarity,
            colorSaturation: averageColorSaturation,
            defectDensity: averageDefects,
            successProbability: successProbability,
            simulationTime: simulationTime
        )
    }

    /// Simulate a single crystal growth run
    private func simulateSingleRun(parameters: SynthesisParameters) -> (
        yield: Double,
        size: Double,
        clarity: Double,
        colorSaturation: Double,
        defects: Double,
        success: Bool
    ) {
        // Temperature effects
        let tempOptimal = getOptimalTemperature(for: parameters.gemstoneType)
        let tempDeviation = abs(parameters.temperature - tempOptimal) / tempOptimal
        let tempFactor = 1.0 - tempDeviation * 0.8

        // Pressure effects
        let pressureOptimal = getOptimalPressure(for: parameters.gemstoneType)
        let pressureDeviation = abs(parameters.pressure - pressureOptimal) / pressureOptimal
        let pressureFactor = 1.0 - pressureDeviation * 0.6

        // pH effects
        let pHOptimal = getOptimalPH(for: parameters.gemstoneType)
        let pHDeviation = abs(parameters.pH - pHOptimal)
        let pHFactor = 1.0 - pHDeviation * 0.5

        // Time effects
        let timeFactor = min(1.0, parameters.duration / 168.0)  // Normalized to 1 week

        // Concentration effects
        let concentrationFactor = min(1.0, parameters.nutrientConcentration * 2.0)

        // Add random variations
        let randomFactor = Double.random(in: 0.8...1.2)

        // Calculate yield (grams)
        let baseYield = parameters.seedCrystalSize * 0.5
        let yield = baseYield * tempFactor * pressureFactor * timeFactor * concentrationFactor * randomFactor
        let finalYield = max(0.1, yield)

        // Calculate crystal size (mm)
        let growthRate = 0.01 * tempFactor * pressureFactor * pHFactor
        let size = parameters.seedCrystalSize + (growthRate * parameters.duration * randomFactor)
        let finalSize = max(parameters.seedCrystalSize, size)

        // Calculate clarity (0-1)
        let coolingFactor = max(0.5, 1.0 - parameters.coolingRate / 10.0)
        let clarity = tempFactor * pHFactor * coolingFactor * Double.random(in: 0.9...1.1)
        let finalClarity = max(0, min(1, clarity))

        // Calculate color saturation (0-1)
        let colorBase = getBaseColorSaturation(for: parameters.gemstoneType)
        let colorSaturation = colorBase * tempFactor * concentrationFactor * Double.random(in: 0.95...1.05)
        let finalColorSaturation = max(0, min(1, colorSaturation))

        // Calculate defect density
        let defectBase = 50.0  // base defects per cubic mm
        let defects = defectBase * (2.0 - tempFactor) * (2.0 - coolingFactor) * Double.random(in: 0.8...1.2)
        let finalDefects = max(0, defects)

        // Determine success
        let overallFactor = tempFactor * pressureFactor * pHFactor
        let success = overallFactor > 0.5 && Double.random(in: 0...1) < overallFactor

        return (
            yield: finalYield,
            size: finalSize,
            clarity: finalClarity,
            colorSaturation: finalColorSaturation,
            defects: finalDefects,
            success: success
        )
    }

    // MARK: - Helper Methods

    private func getOptimalTemperature(for gemstone: GemstoneType) -> Double {
        switch gemstone {
        case .redBeryl: return 520
        case .alexandrite: return 675
        case .tanzanite: return 600
        case .paraibaTourmaline: return 550
        }
    }

    private func getOptimalPressure(for gemstone: GemstoneType) -> Double {
        switch gemstone {
        case .redBeryl: return 200
        case .alexandrite: return 275
        case .tanzanite: return 275
        case .paraibaTourmaline: return 200
        }
    }

    private func getOptimalPH(for gemstone: GemstoneType) -> Double {
        switch gemstone {
        case .redBeryl: return 6.5
        case .alexandrite: return 7.0
        case .tanzanite: return 7.0
        case .paraibaTourmaline: return 6.0
        }
    }

    private func getBaseColorSaturation(for gemstone: GemstoneType) -> Double {
        switch gemstone {
        case .redBeryl: return 0.85
        case .alexandrite: return 0.90
        case .tanzanite: return 0.88
        case .paraibaTourmaline: return 0.92
        }
    }
}