import XCTest
@testable import DentiMatch

final class AppTests: XCTestCase {

    // MARK: - StoreManager Tests

    func testStoreManagerInitialState() {
        let manager = StoreManager()
        XCTAssertFalse(manager.isSubscribed, "User should not be subscribed on first launch")
        XCTAssertTrue(manager.products.isEmpty, "Products should be empty before loading")
        XCTAssertNil(manager.activeSubscription, "No active subscription initially")
        XCTAssertNil(manager.errorMessage, "No error on init")
        XCTAssertFalse(manager.isPurchasing, "Should not be purchasing on init")
    }

    func testProductIdentifiersAreUnique() {
        let ids = StoreManager.allProductIDs
        XCTAssertEqual(ids.count, 3, "Should have exactly 3 product identifiers")
    }

    // MARK: - Patient Model Tests

    func testPatientFullName() {
        let patient = Patient(
            firstName: "Jane",
            lastName: "Smith",
            dateOfBirth: Date()
        )
        XCTAssertEqual(patient.fullName, "Jane Smith")
    }

    func testPatientAge() {
        let calendar = Calendar.current
        let thirtyYearsAgo = calendar.date(byAdding: .year, value: -30, to: Date())!
        let patient = Patient(
            firstName: "Test",
            lastName: "Patient",
            dateOfBirth: thirtyYearsAgo
        )
        XCTAssertEqual(patient.age, 30)
    }

    // MARK: - Dental Chart Tests

    func testFullMouthCreation() {
        let teeth = Tooth.createFullMouth()
        XCTAssertEqual(teeth.count, 32, "Full mouth should have 32 teeth")
        XCTAssertEqual(teeth.first?.number, 1)
        XCTAssertEqual(teeth.last?.number, 32)
    }

    func testToothQuadrants() {
        let tooth1 = Tooth(number: 1)
        XCTAssertEqual(tooth1.quadrant, "Upper Right")

        let tooth9 = Tooth(number: 9)
        XCTAssertEqual(tooth9.quadrant, "Upper Left")

        let tooth17 = Tooth(number: 17)
        XCTAssertEqual(tooth17.quadrant, "Lower Left")

        let tooth25 = Tooth(number: 25)
        XCTAssertEqual(tooth25.quadrant, "Lower Right")
    }

    // MARK: - Case Presentation Tests

    func testCasePresentationOutOfPocket() {
        let casePresentation = CasePresentation(
            patientId: UUID(),
            title: "Test Case",
            totalCost: 5000,
            insuranceEstimate: 2000
        )
        XCTAssertEqual(casePresentation.outOfPocketCost, 3000)
    }

    func testFinancingOptionGeneration() {
        var casePresentation = CasePresentation(
            patientId: UUID(),
            title: "Test Case",
            totalCost: 3000,
            insuranceEstimate: 500
        )
        casePresentation.generateFinancingOptions()
        XCTAssertFalse(casePresentation.financingOptions.isEmpty, "Should generate financing options for qualifying amount")
    }

    // MARK: - Financing Service Tests

    func testFinancingOptionsForSmallAmount() {
        let service = FinancingService()
        let options = service.generateFinancingOptions(for: 100)
        // Should at least have cash option
        XCTAssertTrue(options.contains(where: { $0.provider == .cash }))
    }

    func testFinancingOptionsForLargeAmount() {
        let service = FinancingService()
        let options = service.generateFinancingOptions(for: 5000)
        // Should have CareCredit options for large amounts
        XCTAssertTrue(options.contains(where: { $0.provider == .careCredit }))
        // Should have in-house option
        XCTAssertTrue(options.contains(where: { $0.provider == .inHouse }))
    }

    // MARK: - DataManager Tests

    func testDataManagerInitialState() {
        let manager = DataManager()
        XCTAssertTrue(manager.patients.isEmpty)
        XCTAssertTrue(manager.dentalCharts.isEmpty)
        XCTAssertTrue(manager.casePresentations.isEmpty)
        XCTAssertFalse(manager.isLoading)
        XCTAssertNil(manager.errorMessage)
    }

    func testPatientSearch() {
        let manager = DataManager()
        let results = manager.searchPatients(query: "")
        XCTAssertTrue(results.isEmpty, "Empty search on empty data should return empty")
    }
}
