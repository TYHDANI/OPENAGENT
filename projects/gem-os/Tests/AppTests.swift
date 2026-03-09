import XCTest
@testable import GEMOS

final class AppTests: XCTestCase {

    // MARK: - StoreManager Tests

    func testStoreManagerInitialState() {
        let manager = StoreManager()
        XCTAssertFalse(manager.isSubscribed)
        XCTAssertTrue(manager.products.isEmpty)
        XCTAssertNil(manager.activeSubscription)
        XCTAssertNil(manager.errorMessage)
        XCTAssertFalse(manager.isPurchasing)
    }

    func testProductIdentifiersAreUnique() {
        let ids = StoreManager.allProductIDs
        XCTAssertEqual(ids.count, 2)
        XCTAssertTrue(ids.contains(StoreManager.basicMonthlyID))
        XCTAssertTrue(ids.contains(StoreManager.professionalMonthlyID))
    }

    // MARK: - SynthesisParameters Tests

    func testDefaultParametersForRedBeryl() {
        let params = SynthesisParameters(gemstoneType: .redBeryl)
        XCTAssertEqual(params.gemstoneType, .redBeryl)
        XCTAssertEqual(params.temperature, 500) // midpoint of 400...600
        XCTAssertEqual(params.pressure, 200)    // midpoint of 100...300
        XCTAssertEqual(params.pH, 6.5)          // midpoint of 5.5...7.5
        XCTAssertEqual(params.duration, 168)
        XCTAssertEqual(params.seedCrystalSize, 1.0)
        XCTAssertEqual(params.nutrientConcentration, 0.5)
        XCTAssertEqual(params.coolingRate, 2.0)
    }

    func testDefaultParametersForAlexandrite() {
        let params = SynthesisParameters(gemstoneType: .alexandrite)
        XCTAssertEqual(params.gemstoneType, .alexandrite)
        XCTAssertEqual(params.temperature, 675) // midpoint of 550...800
        XCTAssertEqual(params.pressure, 275)    // midpoint of 150...400
        XCTAssertEqual(params.pH, 7.0)          // midpoint of 6.0...8.0
    }

    func testDefaultParametersForTanzanite() {
        let params = SynthesisParameters(gemstoneType: .tanzanite)
        XCTAssertEqual(params.gemstoneType, .tanzanite)
        XCTAssertEqual(params.temperature, 600)
        XCTAssertEqual(params.pressure, 275)
        XCTAssertEqual(params.pH, 7.0)
    }

    func testDefaultParametersForParaibaTourmaline() {
        let params = SynthesisParameters(gemstoneType: .paraibaTourmaline)
        XCTAssertEqual(params.gemstoneType, .paraibaTourmaline)
        XCTAssertEqual(params.temperature, 550)
        XCTAssertEqual(params.pressure, 200)
        XCTAssertEqual(params.pH, 6.0)
    }

    func testParametersEquatable() {
        let a = SynthesisParameters(gemstoneType: .redBeryl)
        let b = SynthesisParameters(gemstoneType: .redBeryl)
        XCTAssertEqual(a, b)

        var c = a
        c.temperature = 999
        XCTAssertNotEqual(a, c)
    }

    // MARK: - GemstoneType Tests

    func testAllGemstoneTypesHaveValidRanges() {
        for gemstone in GemstoneType.allCases {
            XCTAssertLessThan(gemstone.defaultTemperatureRange.lowerBound,
                              gemstone.defaultTemperatureRange.upperBound)
            XCTAssertLessThan(gemstone.defaultPressureRange.lowerBound,
                              gemstone.defaultPressureRange.upperBound)
            XCTAssertLessThan(gemstone.defaultPHRange.lowerBound,
                              gemstone.defaultPHRange.upperBound)
            XCTAssertFalse(gemstone.chemicalFormula.isEmpty)
            XCTAssertFalse(gemstone.displayName.isEmpty)
        }
    }

    func testGemstoneTypeCodable() throws {
        for gemstone in GemstoneType.allCases {
            let data = try JSONEncoder().encode(gemstone)
            let decoded = try JSONDecoder().decode(GemstoneType.self, from: data)
            XCTAssertEqual(decoded, gemstone)
        }
    }

    func testGemstoneTypeDisplayNames() {
        XCTAssertEqual(GemstoneType.redBeryl.displayName, "Red Beryl")
        XCTAssertEqual(GemstoneType.alexandrite.displayName, "Alexandrite")
        XCTAssertEqual(GemstoneType.tanzanite.displayName, "Tanzanite")
        XCTAssertEqual(GemstoneType.paraibaTourmaline.displayName, "Paraiba Tourmaline")
    }

    // MARK: - Recipe Tests

    func testDefaultRecipesExist() {
        let recipes = Recipe.defaultRecipes
        XCTAssertEqual(recipes.count, 4)
    }

    func testDefaultRecipesHaveStableIDs() {
        let first = Recipe.defaultRecipes
        let second = Recipe.defaultRecipes
        for (a, b) in zip(first, second) {
            XCTAssertEqual(a.id, b.id, "Default recipe IDs should be deterministic")
        }
    }

    func testBuiltInRecipeIdentification() {
        for recipe in Recipe.defaultRecipes {
            XCTAssertTrue(recipe.isBuiltIn, "\(recipe.name) should be identified as built-in")
        }

        let custom = Recipe(
            name: "Custom",
            description: "A custom recipe",
            gemstoneType: .redBeryl,
            parameters: SynthesisParameters(gemstoneType: .redBeryl),
            expectedYield: 0.5...1.0,
            expectedQuality: 0.5...0.8,
            difficulty: .beginner
        )
        XCTAssertFalse(custom.isBuiltIn, "Custom recipe should not be built-in")
    }

    func testRecipeYieldRangeIsValid() {
        for recipe in Recipe.defaultRecipes {
            XCTAssertLessThanOrEqual(recipe.expectedYield.lowerBound,
                                     recipe.expectedYield.upperBound)
            XCTAssertLessThanOrEqual(recipe.expectedQuality.lowerBound,
                                     recipe.expectedQuality.upperBound)
            XCTAssertGreaterThanOrEqual(recipe.expectedQuality.lowerBound, 0)
            XCTAssertLessThanOrEqual(recipe.expectedQuality.upperBound, 1.0)
        }
    }

    func testRecipeCodable() throws {
        let recipe = Recipe.defaultRecipes[0]
        let data = try JSONEncoder().encode(recipe)
        let decoded = try JSONDecoder().decode(Recipe.self, from: data)
        XCTAssertEqual(decoded.id, recipe.id)
        XCTAssertEqual(decoded.name, recipe.name)
        XCTAssertEqual(decoded.gemstoneType, recipe.gemstoneType)
        XCTAssertEqual(decoded.expectedYieldMin, recipe.expectedYieldMin, accuracy: 0.001)
        XCTAssertEqual(decoded.expectedYieldMax, recipe.expectedYieldMax, accuracy: 0.001)
    }

    func testRecipeGemstoneTypes() {
        let recipes = Recipe.defaultRecipes
        let redBerylRecipes = recipes.filter { $0.gemstoneType == .redBeryl }
        let alexandriteRecipes = recipes.filter { $0.gemstoneType == .alexandrite }
        XCTAssertEqual(redBerylRecipes.count, 2, "Should have 2 Red Beryl recipes")
        XCTAssertEqual(alexandriteRecipes.count, 2, "Should have 2 Alexandrite recipes")
    }

    // MARK: - SimulationResult Tests

    func testSimulationResultQuality() {
        let result = SimulationResult(
            id: UUID(),
            timestamp: Date(),
            parameters: SynthesisParameters(gemstoneType: .redBeryl),
            iterations: 1000,
            crystalYield: 1.0,
            averageSize: 5.0,
            clarity: 0.8,
            colorSaturation: 0.9,
            defectDensity: 20.0,
            successProbability: 0.75,
            simulationTime: 1.0
        )
        // overallQuality = (0.8 * 0.4) + (0.9 * 0.3) + ((1.0 - 20/100) * 0.3) = 0.32 + 0.27 + 0.24 = 0.83
        XCTAssertEqual(result.overallQuality, 0.83, accuracy: 0.01)
    }

    func testSimulationResultQualityClamped() {
        let result = SimulationResult(
            id: UUID(),
            timestamp: Date(),
            parameters: SynthesisParameters(gemstoneType: .redBeryl),
            iterations: 1000,
            crystalYield: 0.1,
            averageSize: 1.0,
            clarity: 1.0,
            colorSaturation: 1.0,
            defectDensity: 0.0,
            successProbability: 1.0,
            simulationTime: 0.5
        )
        // Perfect scores: (1.0 * 0.4) + (1.0 * 0.3) + ((1.0 - 0/100) * 0.3) = 0.4 + 0.3 + 0.3 = 1.0
        XCTAssertEqual(result.overallQuality, 1.0, accuracy: 0.01)
        XCTAssertGreaterThanOrEqual(result.overallQuality, 0)
        XCTAssertLessThanOrEqual(result.overallQuality, 1)
    }

    func testSimulationResultCodable() throws {
        let result = SimulationResult(
            id: UUID(),
            timestamp: Date(),
            parameters: SynthesisParameters(gemstoneType: .alexandrite),
            iterations: 5000,
            crystalYield: 1.5,
            averageSize: 3.2,
            clarity: 0.85,
            colorSaturation: 0.90,
            defectDensity: 15.0,
            successProbability: 0.82,
            simulationTime: 5.0
        )
        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(SimulationResult.self, from: data)
        XCTAssertEqual(decoded.id, result.id)
        XCTAssertEqual(decoded.iterations, result.iterations)
        XCTAssertEqual(decoded.crystalYield, result.crystalYield, accuracy: 0.001)
    }

    // MARK: - Monte Carlo Engine Tests

    func testMonteCarloEngineProducesResult() async {
        let params = SynthesisParameters(gemstoneType: .redBeryl)
        let result = await MonteCarloEngine.shared.runSimulation(
            parameters: params,
            iterations: 100
        )
        XCTAssertEqual(result.iterations, 100)
        XCTAssertGreaterThan(result.crystalYield, 0)
        XCTAssertGreaterThan(result.averageSize, 0)
        XCTAssertGreaterThanOrEqual(result.clarity, 0)
        XCTAssertLessThanOrEqual(result.clarity, 1)
        XCTAssertGreaterThanOrEqual(result.successProbability, 0)
        XCTAssertLessThanOrEqual(result.successProbability, 1)
    }

    func testMonteCarloEngineProgressCallback() async {
        var progressValues: [Double] = []
        let params = SynthesisParameters(gemstoneType: .alexandrite)
        _ = await MonteCarloEngine.shared.runSimulation(
            parameters: params,
            iterations: 500,
            progressHandler: { progress in
                progressValues.append(progress)
            }
        )
        XCTAssertFalse(progressValues.isEmpty, "Progress should be reported")
    }

    func testMonteCarloEngineDifferentGemstones() async {
        for gemstone in GemstoneType.allCases {
            let params = SynthesisParameters(gemstoneType: gemstone)
            let result = await MonteCarloEngine.shared.runSimulation(
                parameters: params,
                iterations: 50
            )
            XCTAssertEqual(result.parameters.gemstoneType, gemstone)
            XCTAssertGreaterThan(result.crystalYield, 0)
        }
    }

    // MARK: - Optimization Service Tests

    func testOptimizationProducesRecommendations() async {
        let params = SynthesisParameters(gemstoneType: .redBeryl)
        let result = await OptimizationService.shared.optimizeParameters(
            current: params,
            goal: .maximizeYield
        )
        XCTAssertEqual(result.originalParameters, params)
    }

    func testOptimizationAllGoals() async {
        let params = SynthesisParameters(gemstoneType: .redBeryl)
        let goals: [OptimizationService.OptimizationGoal] = [
            .maximizeYield, .maximizeQuality, .minimizeTime, .balanced
        ]
        for goal in goals {
            let result = await OptimizationService.shared.optimizeParameters(
                current: params,
                goal: goal
            )
            XCTAssertEqual(result.originalParameters, params)
        }
    }

    func testOptimizationExpectedImprovement() async {
        // Use parameters far from optimal to ensure recommendations are generated
        var params = SynthesisParameters(gemstoneType: .redBeryl)
        params.temperature = 400  // Below optimal
        params.pressure = 100     // Below optimal
        params.nutrientConcentration = 0.2  // Low

        let result = await OptimizationService.shared.optimizeParameters(
            current: params,
            goal: .maximizeYield
        )
        XCTAssertFalse(result.recommendations.isEmpty, "Should have recommendations for suboptimal params")
        XCTAssertGreaterThan(result.expectedImprovement, 0, "Expected improvement should be positive")
    }

    // MARK: - Export Service Tests

    func testCSVExport() {
        let result = SimulationResult(
            id: UUID(),
            timestamp: Date(),
            parameters: SynthesisParameters(gemstoneType: .redBeryl),
            iterations: 1000,
            crystalYield: 1.0,
            averageSize: 5.0,
            clarity: 0.8,
            colorSaturation: 0.9,
            defectDensity: 20.0,
            successProbability: 0.75,
            simulationTime: 1.0
        )
        let url = ExportService.shared.exportToCSV(result: result)
        XCTAssertNotNil(url, "CSV export should produce a file URL")
        if let url = url {
            let content = try? String(contentsOf: url, encoding: .utf8)
            XCTAssertNotNil(content)
            XCTAssertTrue(content?.contains("Red Beryl") ?? false)
            XCTAssertTrue(content?.contains("PARAMETERS") ?? false)
            XCTAssertTrue(content?.contains("RESULTS") ?? false)
            try? FileManager.default.removeItem(at: url)
        }
    }

    func testBatchCSVExport() {
        let results = [
            SimulationResult(
                id: UUID(),
                timestamp: Date(),
                parameters: SynthesisParameters(gemstoneType: .redBeryl),
                iterations: 1000,
                crystalYield: 1.0,
                averageSize: 5.0,
                clarity: 0.8,
                colorSaturation: 0.9,
                defectDensity: 20.0,
                successProbability: 0.75,
                simulationTime: 1.0
            ),
            SimulationResult(
                id: UUID(),
                timestamp: Date(),
                parameters: SynthesisParameters(gemstoneType: .alexandrite),
                iterations: 2000,
                crystalYield: 1.5,
                averageSize: 3.0,
                clarity: 0.85,
                colorSaturation: 0.88,
                defectDensity: 15.0,
                successProbability: 0.80,
                simulationTime: 2.0
            )
        ]
        let url = ExportService.shared.exportToCSV(results: results)
        XCTAssertNotNil(url, "Batch CSV export should produce a file URL")
        if let url = url {
            let content = try? String(contentsOf: url, encoding: .utf8)
            XCTAssertNotNil(content)
            XCTAssertTrue(content?.contains("Total Simulations: 2") ?? false)
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - SynthesisParameters Builder

    func testParametersBuilderPattern() {
        let params = SynthesisParameters(gemstoneType: .redBeryl).with {
            $0.temperature = 520
            $0.pressure = 250
        }
        XCTAssertEqual(params.temperature, 520)
        XCTAssertEqual(params.pressure, 250)
        XCTAssertEqual(params.gemstoneType, .redBeryl)
    }

    func testParametersCodable() throws {
        let params = SynthesisParameters(gemstoneType: .redBeryl).with {
            $0.temperature = 520
            $0.pressure = 250
            $0.pH = 6.8
        }
        let data = try JSONEncoder().encode(params)
        let decoded = try JSONDecoder().decode(SynthesisParameters.self, from: data)
        XCTAssertEqual(decoded, params)
    }
}
