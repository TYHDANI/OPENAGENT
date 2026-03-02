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

    // MARK: - Recipe Tests

    func testDefaultRecipesExist() {
        let recipes = Recipe.defaultRecipes
        XCTAssertGreaterThanOrEqual(recipes.count, 4)
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

    // MARK: - Optimization Service Tests

    func testOptimizationProducesRecommendations() async {
        let params = SynthesisParameters(gemstoneType: .redBeryl)
        let result = await OptimizationService.shared.optimizeParameters(
            current: params,
            goal: .maximizeYield
        )
        XCTAssertEqual(result.originalParameters, params)
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
}
