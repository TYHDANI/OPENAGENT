import Foundation

/// A synthesis recipe with preset parameters and expected results
struct Recipe: Codable, Identifiable {
    var id: UUID
    var name: String
    var description: String
    var gemstoneType: GemstoneType
    var parameters: SynthesisParameters
    var expectedYieldMin: Double   // grams
    var expectedYieldMax: Double   // grams
    var expectedQualityMin: Double // 0-1 scale
    var expectedQualityMax: Double // 0-1 scale
    var difficulty: Difficulty
    var notes: String

    var expectedYield: ClosedRange<Double> { expectedYieldMin...expectedYieldMax }
    var expectedQuality: ClosedRange<Double> { expectedQualityMin...expectedQualityMax }

    enum Difficulty: String, Codable, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert"
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        gemstoneType: GemstoneType,
        parameters: SynthesisParameters,
        expectedYield: ClosedRange<Double>,
        expectedQuality: ClosedRange<Double>,
        difficulty: Difficulty,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.gemstoneType = gemstoneType
        self.parameters = parameters
        self.expectedYieldMin = expectedYield.lowerBound
        self.expectedYieldMax = expectedYield.upperBound
        self.expectedQualityMin = expectedQuality.lowerBound
        self.expectedQualityMax = expectedQuality.upperBound
        self.difficulty = difficulty
        self.notes = notes
    }

    /// Stable UUIDs for built-in recipes (deterministic so they can be identified)
    private static let classicBixbiteID = UUID(uuidString: "00000000-0001-0000-0000-000000000001")!
    private static let highYieldRedBerylID = UUID(uuidString: "00000000-0001-0000-0000-000000000002")!
    private static let premiumAlexandriteID = UUID(uuidString: "00000000-0001-0000-0000-000000000003")!
    private static let standardAlexandriteID = UUID(uuidString: "00000000-0001-0000-0000-000000000004")!

    static let builtInRecipeIDs: Set<UUID> = [
        classicBixbiteID, highYieldRedBerylID, premiumAlexandriteID, standardAlexandriteID
    ]

    var isBuiltIn: Bool { Self.builtInRecipeIDs.contains(id) }

    /// Default recipes for initial database
    static let defaultRecipes: [Recipe] = [
            // Red Beryl recipes
            Recipe(
                id: classicBixbiteID,
                name: "Classic Bixbite",
                description: "Traditional hydrothermal method for synthetic red beryl",
                gemstoneType: .redBeryl,
                parameters: SynthesisParameters(gemstoneType: .redBeryl).with {
                    $0.temperature = 500
                    $0.pressure = 200
                    $0.pH = 6.5
                    $0.duration = 240
                    $0.nutrientConcentration = 0.45
                },
                expectedYield: 0.5...1.2,
                expectedQuality: 0.7...0.85,
                difficulty: .intermediate,
                notes: "Produces consistent color but smaller crystals"
            ),
            Recipe(
                id: highYieldRedBerylID,
                name: "High-Yield Red Beryl",
                description: "Optimized for maximum crystal growth rate",
                gemstoneType: .redBeryl,
                parameters: SynthesisParameters(gemstoneType: .redBeryl).with {
                    $0.temperature = 550
                    $0.pressure = 250
                    $0.pH = 7.0
                    $0.duration = 168
                    $0.nutrientConcentration = 0.65
                },
                expectedYield: 1.5...2.5,
                expectedQuality: 0.6...0.75,
                difficulty: .beginner,
                notes: "Higher yield but slightly lower clarity"
            ),

            // Alexandrite recipes
            Recipe(
                id: premiumAlexandriteID,
                name: "Premium Alexandrite",
                description: "High-quality synthetic alexandrite with strong color change",
                gemstoneType: .alexandrite,
                parameters: SynthesisParameters(gemstoneType: .alexandrite).with {
                    $0.temperature = 675
                    $0.pressure = 275
                    $0.pH = 7.2
                    $0.duration = 336
                    $0.nutrientConcentration = 0.55
                },
                expectedYield: 0.8...1.5,
                expectedQuality: 0.85...0.95,
                difficulty: .expert,
                notes: "Excellent color change effect but requires precise control"
            ),
            Recipe(
                id: standardAlexandriteID,
                name: "Standard Alexandrite",
                description: "Balanced approach for consistent results",
                gemstoneType: .alexandrite,
                parameters: SynthesisParameters(gemstoneType: .alexandrite).with {
                    $0.temperature = 625
                    $0.pressure = 225
                    $0.pH = 6.8
                    $0.duration = 240
                    $0.nutrientConcentration = 0.50
                },
                expectedYield: 1.0...2.0,
                expectedQuality: 0.75...0.85,
                difficulty: .intermediate,
                notes: "Good balance of yield and quality"
            )
        ]
}

// Helper extension for builder pattern
extension SynthesisParameters {
    func with(_ transform: (inout SynthesisParameters) -> Void) -> SynthesisParameters {
        var copy = self
        transform(&copy)
        return copy
    }
}
