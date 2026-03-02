import XCTest
import SwiftData
@testable import MaterialSource

final class RFQServiceTests: XCTestCase {
    var modelContainer: ModelContainer!
    var rfqService: RFQService!
    var testMaterial: Material!
    var testSupplier: Supplier!

    @MainActor override func setUp() async throws {
        // Create in-memory model container for testing
        let schema = Schema([
            Material.self,
            Supplier.self,
            Specification.self,
            MaterialProperty.self,
            RFQ.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])

        rfqService = RFQService(modelContext: modelContainer.mainContext)

        // Create test data
        testSupplier = Supplier(
            name: "Test Supplier Inc.",
            location: "USA",
            leadTimeRange: "2-4 weeks",
            minimumOrderQuantity: "10 kg"
        )

        testMaterial = Material(
            name: "Test Alloy",
            category: "Test Materials",
            descriptionText: "A test material for unit testing",
            suppliers: [testSupplier]
        )

        modelContainer.mainContext.insert(testMaterial)

        do {
            try modelContainer.mainContext.save()
        } catch {
            XCTFail("Failed to save test data: \(error)")
        }
    }

    @MainActor func testCreateRFQAsSubscribedUser() async throws {
        // When
        try await rfqService.createRFQ(
            material: testMaterial,
            supplier: testSupplier,
            quantity: "100",
            unit: "kg",
            specifications: "Test specifications",
            targetDate: Date().addingTimeInterval(30 * 24 * 60 * 60), // 30 days
            isSubscribed: true
        )

        // Then
        await rfqService.loadRFQs()
        XCTAssertEqual(rfqService.activeRFQs.count, 1)

        let rfq = rfqService.activeRFQs.first
        XCTAssertNotNil(rfq)
        XCTAssertEqual(rfq?.quantity, "100")
        XCTAssertEqual(rfq?.unit, "kg")
        XCTAssertEqual(rfq?.status, .draft)
    }

    @MainActor func testCreateRFQAsFreeUser() async throws {
        // Given - Create first RFQ as free user
        try await rfqService.createRFQ(
            material: testMaterial,
            supplier: testSupplier,
            quantity: "50",
            unit: "kg",
            specifications: "First RFQ",
            targetDate: nil,
            isSubscribed: false
        )

        // When - Try to create second RFQ as free user
        do {
            try await rfqService.createRFQ(
                material: testMaterial,
                supplier: testSupplier,
                quantity: "100",
                unit: "kg",
                specifications: "Second RFQ",
                targetDate: nil,
                isSubscribed: false
            )
            XCTFail("Should have thrown limit exceeded error")
        } catch {
            // Then - Should fail with limit exceeded
            XCTAssertTrue(error is RFQError)
        }
    }

    @MainActor func testSubmitRFQ() async throws {
        // Given
        let rfq = RFQ(
            material: testMaterial,
            supplier: testSupplier,
            quantity: "75",
            unit: "kg",
            specifications: "Rush order"
        )
        modelContainer.mainContext.insert(rfq)
        try modelContainer.mainContext.save()

        // When
        try await rfqService.submitRFQ(rfq)

        // Then
        XCTAssertEqual(rfq.status, .submitted)
        XCTAssertNotNil(rfq.lastUpdatedDate)
    }

    @MainActor func testGetRFQsByStatus() async throws {
        // Given - Create RFQs with different statuses
        let draftRFQ = createRFQ(status: .draft)
        let submittedRFQ = createRFQ(status: .submitted)
        let quotedRFQ = createRFQ(status: .quoted)

        modelContainer.mainContext.insert(draftRFQ)
        modelContainer.mainContext.insert(submittedRFQ)
        modelContainer.mainContext.insert(quotedRFQ)
        try modelContainer.mainContext.save()

        // When
        let draftRFQs = await rfqService.getRFQsByStatus(.draft)
        let quotedRFQs = await rfqService.getRFQsByStatus(.quoted)

        // Then
        XCTAssertEqual(draftRFQs.count, 1)
        XCTAssertEqual(quotedRFQs.count, 1)
    }

    @MainActor func testSimulateQuoteResponse() async throws {
        // Given
        let rfq = createRFQ(status: .pending)
        modelContainer.mainContext.insert(rfq)
        try modelContainer.mainContext.save()

        // When
        await rfqService.simulateQuoteResponse(rfq)

        // Then
        XCTAssertEqual(rfq.status, .quoted)
        XCTAssertNotNil(rfq.quoteReceived)
        XCTAssertGreaterThan(rfq.quoteReceived?.totalPrice ?? 0, 0)
    }

    @MainActor func testCompareQuotes() async throws {
        // Given - Create multiple quoted RFQs for the same material
        let supplier1 = Supplier(
            name: "Supplier A",
            location: "USA",
            leadTimeRange: "1-2 weeks",
            minimumOrderQuantity: "5 kg"
        )

        let supplier2 = Supplier(
            name: "Supplier B",
            location: "Canada",
            leadTimeRange: "2-3 weeks",
            minimumOrderQuantity: "10 kg"
        )

        modelContainer.mainContext.insert(supplier1)
        modelContainer.mainContext.insert(supplier2)

        let rfq1 = RFQ(
            material: testMaterial,
            supplier: supplier1,
            quantity: "100",
            unit: "kg",
            specifications: "Standard"
        )
        rfq1.status = .quoted
        rfq1.quoteReceived = Quote(
            unitPrice: 50.0,
            totalPrice: 5000.0,
            currency: "USD",
            leadTime: "1-2 weeks",
            validUntil: Date().addingTimeInterval(30 * 24 * 60 * 60)
        )

        let rfq2 = RFQ(
            material: testMaterial,
            supplier: supplier2,
            quantity: "100",
            unit: "kg",
            specifications: "Standard"
        )
        rfq2.status = .quoted
        rfq2.quoteReceived = Quote(
            unitPrice: 45.0,
            totalPrice: 4500.0,
            currency: "USD",
            leadTime: "2-3 weeks",
            validUntil: Date().addingTimeInterval(30 * 24 * 60 * 60)
        )

        modelContainer.mainContext.insert(rfq1)
        modelContainer.mainContext.insert(rfq2)
        try modelContainer.mainContext.save()

        // When
        let comparisons = await rfqService.compareQuotes(for: testMaterial)

        // Then
        XCTAssertEqual(comparisons.count, 2)
        XCTAssertEqual(comparisons.first?.unitPrice, 45.0) // Should be sorted by price
        XCTAssertEqual(comparisons.first?.supplier.name, "Supplier B")
    }

    // MARK: - Helpers

    private func createRFQ(status: RFQStatus) -> RFQ {
        let rfq = RFQ(
            material: testMaterial,
            supplier: testSupplier,
            quantity: "100",
            unit: "kg",
            specifications: "Test"
        )
        rfq.status = status
        return rfq
    }
}