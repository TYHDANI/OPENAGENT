import Foundation

/// Service for optimizing synthesis parameters based on desired outcomes
final class OptimizationService {
    static let shared = OptimizationService()

    private init() {}

    enum OptimizationGoal {
        case maximizeYield
        case maximizeQuality
        case minimizeTime
        case balanced

        var displayName: String {
            switch self {
            case .maximizeYield: return "Maximum Yield"
            case .maximizeQuality: return "Maximum Quality"
            case .minimizeTime: return "Fastest Growth"
            case .balanced: return "Balanced"
            }
        }
    }

    struct OptimizationResult {
        let originalParameters: SynthesisParameters
        let optimizedParameters: SynthesisParameters
        let recommendations: [Recommendation]
        let expectedImprovement: Double  // Percentage

        struct Recommendation {
            let parameter: String
            let currentValue: String
            let recommendedValue: String
            let reason: String
            let impact: Impact

            enum Impact: String {
                case high = "High"
                case medium = "Medium"
                case low = "Low"

                var color: String {
                    switch self {
                    case .high: return "red"
                    case .medium: return "orange"
                    case .low: return "yellow"
                    }
                }
            }
        }
    }

    /// Optimize parameters for a specific goal
    func optimizeParameters(
        current: SynthesisParameters,
        goal: OptimizationGoal
    ) async -> OptimizationResult {
        var optimized = current
        var recommendations: [OptimizationResult.Recommendation] = []

        switch goal {
        case .maximizeYield:
            // Temperature optimization for yield
            let optimalTemp = getYieldOptimalTemperature(for: current.gemstoneType)
            if abs(current.temperature - optimalTemp) > 10 {
                optimized.temperature = optimalTemp
                recommendations.append(.init(
                    parameter: "Temperature",
                    currentValue: "\(Int(current.temperature))°C",
                    recommendedValue: "\(Int(optimalTemp))°C",
                    reason: "Higher temperatures increase crystal growth rate",
                    impact: .high
                ))
            }

            // Pressure optimization for yield
            let optimalPressure = getYieldOptimalPressure(for: current.gemstoneType)
            if abs(current.pressure - optimalPressure) > 20 {
                optimized.pressure = optimalPressure
                recommendations.append(.init(
                    parameter: "Pressure",
                    currentValue: "\(Int(current.pressure)) MPa",
                    recommendedValue: "\(Int(optimalPressure)) MPa",
                    reason: "Optimal pressure enhances nutrient transport",
                    impact: .high
                ))
            }

            // Concentration optimization
            if current.nutrientConcentration < 0.6 {
                optimized.nutrientConcentration = 0.65
                recommendations.append(.init(
                    parameter: "Nutrient Concentration",
                    currentValue: String(format: "%.2f mol/L", current.nutrientConcentration),
                    recommendedValue: "0.65 mol/L",
                    reason: "Higher concentration provides more growth material",
                    impact: .medium
                ))
            }

        case .maximizeQuality:
            // Temperature optimization for quality
            let optimalTemp = getQualityOptimalTemperature(for: current.gemstoneType)
            if abs(current.temperature - optimalTemp) > 10 {
                optimized.temperature = optimalTemp
                recommendations.append(.init(
                    parameter: "Temperature",
                    currentValue: "\(Int(current.temperature))°C",
                    recommendedValue: "\(Int(optimalTemp))°C",
                    reason: "Precise temperature control reduces defects",
                    impact: .high
                ))
            }

            // Cooling rate optimization
            if current.coolingRate > 1.5 {
                optimized.coolingRate = 1.0
                recommendations.append(.init(
                    parameter: "Cooling Rate",
                    currentValue: String(format: "%.1f°C/hour", current.coolingRate),
                    recommendedValue: "1.0°C/hour",
                    reason: "Slower cooling prevents thermal stress and improves clarity",
                    impact: .high
                ))
            }

            // pH optimization
            let optimalPH = getQualityOptimalPH(for: current.gemstoneType)
            if abs(current.pH - optimalPH) > 0.3 {
                optimized.pH = optimalPH
                recommendations.append(.init(
                    parameter: "pH",
                    currentValue: String(format: "%.1f", current.pH),
                    recommendedValue: String(format: "%.1f", optimalPH),
                    reason: "Optimal pH reduces inclusion formation",
                    impact: .medium
                ))
            }

        case .minimizeTime:
            // Duration optimization
            if current.duration > 120 {
                optimized.duration = 96
                recommendations.append(.init(
                    parameter: "Duration",
                    currentValue: "\(Int(current.duration)) hours",
                    recommendedValue: "96 hours",
                    reason: "Shorter cycles with optimized parameters",
                    impact: .high
                ))
            }

            // Temperature boost for speed
            let speedTemp = min(current.gemstoneType.defaultTemperatureRange.upperBound,
                               current.temperature + 25)
            if speedTemp > current.temperature {
                optimized.temperature = speedTemp
                recommendations.append(.init(
                    parameter: "Temperature",
                    currentValue: "\(Int(current.temperature))°C",
                    recommendedValue: "\(Int(speedTemp))°C",
                    reason: "Higher temperature accelerates growth",
                    impact: .medium
                ))
            }

        case .balanced:
            // Find middle ground between yield and quality
            let balancedTemp = (getYieldOptimalTemperature(for: current.gemstoneType) +
                               getQualityOptimalTemperature(for: current.gemstoneType)) / 2
            if abs(current.temperature - balancedTemp) > 15 {
                optimized.temperature = balancedTemp
                recommendations.append(.init(
                    parameter: "Temperature",
                    currentValue: "\(Int(current.temperature))°C",
                    recommendedValue: "\(Int(balancedTemp))°C",
                    reason: "Balanced for both yield and quality",
                    impact: .medium
                ))
            }

            // Moderate cooling rate
            if current.coolingRate > 2.5 || current.coolingRate < 1.5 {
                optimized.coolingRate = 2.0
                recommendations.append(.init(
                    parameter: "Cooling Rate",
                    currentValue: String(format: "%.1f°C/hour", current.coolingRate),
                    recommendedValue: "2.0°C/hour",
                    reason: "Moderate cooling balances quality and time",
                    impact: .low
                ))
            }
        }

        // Calculate expected improvement
        let improvement = calculateExpectedImprovement(
            original: current,
            optimized: optimized,
            goal: goal
        )

        return OptimizationResult(
            originalParameters: current,
            optimizedParameters: optimized,
            recommendations: recommendations,
            expectedImprovement: improvement
        )
    }

    // MARK: - Private Methods

    private func getYieldOptimalTemperature(for gemstone: GemstoneType) -> Double {
        switch gemstone {
        case .redBeryl: return 550
        case .alexandrite: return 700
        case .tanzanite: return 650
        case .paraibaTourmaline: return 600
        }
    }

    private func getQualityOptimalTemperature(for gemstone: GemstoneType) -> Double {
        switch gemstone {
        case .redBeryl: return 480
        case .alexandrite: return 650
        case .tanzanite: return 575
        case .paraibaTourmaline: return 525
        }
    }

    private func getYieldOptimalPressure(for gemstone: GemstoneType) -> Double {
        switch gemstone {
        case .redBeryl: return 250
        case .alexandrite: return 325
        case .tanzanite: return 300
        case .paraibaTourmaline: return 240
        }
    }

    private func getQualityOptimalPH(for gemstone: GemstoneType) -> Double {
        switch gemstone {
        case .redBeryl: return 6.5
        case .alexandrite: return 7.0
        case .tanzanite: return 7.0
        case .paraibaTourmaline: return 6.0
        }
    }

    private func calculateExpectedImprovement(
        original: SynthesisParameters,
        optimized: SynthesisParameters,
        goal: OptimizationGoal
    ) -> Double {
        // Simplified improvement calculation
        var changes = 0
        var totalChange: Double = 0

        if original.temperature != optimized.temperature {
            changes += 1
            totalChange += abs(original.temperature - optimized.temperature) / original.temperature
        }

        if original.pressure != optimized.pressure {
            changes += 1
            totalChange += abs(original.pressure - optimized.pressure) / original.pressure
        }

        if original.pH != optimized.pH {
            changes += 1
            totalChange += abs(original.pH - optimized.pH) / original.pH
        }

        if original.coolingRate != optimized.coolingRate {
            changes += 1
            totalChange += abs(original.coolingRate - optimized.coolingRate) / original.coolingRate
        }

        if changes == 0 { return 0 }

        let averageChange = totalChange / Double(changes)

        // Goal-specific multipliers
        switch goal {
        case .maximizeYield:
            return averageChange * 30  // Up to 30% yield improvement
        case .maximizeQuality:
            return averageChange * 25  // Up to 25% quality improvement
        case .minimizeTime:
            return averageChange * 40  // Up to 40% time reduction
        case .balanced:
            return averageChange * 20  // Up to 20% overall improvement
        }
    }
}