import Foundation

/// Parameters for hydrothermal gemstone synthesis simulation
struct SynthesisParameters: Codable, Equatable {
    var gemstoneType: GemstoneType
    var temperature: Double  // °C
    var pressure: Double     // MPa
    var pH: Double
    var duration: Double     // hours
    var seedCrystalSize: Double  // mm
    var nutrientConcentration: Double  // mol/L
    var coolingRate: Double  // °C/hour

    /// Initialize with default values for a specific gemstone
    init(gemstoneType: GemstoneType) {
        self.gemstoneType = gemstoneType
        self.temperature = (gemstoneType.defaultTemperatureRange.lowerBound + gemstoneType.defaultTemperatureRange.upperBound) / 2
        self.pressure = (gemstoneType.defaultPressureRange.lowerBound + gemstoneType.defaultPressureRange.upperBound) / 2
        self.pH = (gemstoneType.defaultPHRange.lowerBound + gemstoneType.defaultPHRange.upperBound) / 2
        self.duration = 168  // 7 days default
        self.seedCrystalSize = 1.0
        self.nutrientConcentration = 0.5
        self.coolingRate = 2.0
    }
}

/// Result of a synthesis simulation
struct SimulationResult: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let parameters: SynthesisParameters
    let iterations: Int
    let crystalYield: Double  // grams
    let averageSize: Double   // mm
    let clarity: Double       // 0-1 scale
    let colorSaturation: Double  // 0-1 scale
    let defectDensity: Double  // defects per cubic mm
    let successProbability: Double  // 0-1 scale
    let simulationTime: TimeInterval  // seconds

    var overallQuality: Double {
        // Weighted average of quality factors
        let qualityScore = (clarity * 0.4) + (colorSaturation * 0.3) + ((1.0 - defectDensity / 100.0) * 0.3)
        return max(0, min(1, qualityScore))
    }
}