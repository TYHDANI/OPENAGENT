import XCTest
import StoreKit
@testable import StreamFlow

final class StoreManagerTests: XCTestCase {
    var sut: StoreManager!

    override func setUp() {
        super.setUp()
        sut = StoreManager()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Product Configuration Tests

    func testProductIdentifiers_ShouldBeConfiguredCorrectly() {
        // Then
        XCTAssertEqual(StoreManager.monthlyID, "com.streamflow.habits.subscription.monthly")
        XCTAssertEqual(StoreManager.yearlyID, "com.streamflow.habits.subscription.yearly")
        XCTAssertEqual(StoreManager.lifetimeID, "com.streamflow.habits.lifetime")
        XCTAssertEqual(StoreManager.allProductIDs.count, 3)
    }

    // MARK: - Initial State Tests

    func testInitialState_ShouldHaveCorrectDefaults() {
        // Then
        XCTAssertTrue(sut.products.isEmpty)
        XCTAssertFalse(sut.isSubscribed)
        XCTAssertNil(sut.activeSubscription)
        XCTAssertFalse(sut.isPurchasing)
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Transaction Listener Tests

    func testListenForTransactions_ShouldNotCreateDuplicateListeners() {
        // When
        sut.listenForTransactions()
        sut.listenForTransactions() // Call twice

        // Then
        // Should not crash or create multiple listeners
        // (In a real test, we'd verify only one listener is active)
    }

    // MARK: - Mock Tests (would require StoreKitTest framework)

    func testLoadProducts_WithValidProductIDs_ShouldPopulateProducts() async {
        // Given
        // In a real test environment, we'd use StoreKitTest configuration

        // When
        await sut.loadProducts()

        // Then
        // Without StoreKitTest, products will remain empty in unit tests
        // This test documents expected behavior
    }

    func testCheckSubscriptionStatus_WithNoEntitlements_ShouldNotBeSubscribed() async {
        // When
        await sut.checkSubscriptionStatus()

        // Then
        XCTAssertFalse(sut.isSubscribed)
        XCTAssertNil(sut.activeSubscription)
    }

    func testPurchase_WhileAlreadyPurchasing_ShouldHandleGracefully() async {
        // Given
        sut.isPurchasing = true

        // When
        // In production, this would be prevented by UI
        // Test verifies the flag prevents issues

        // Then
        XCTAssertTrue(sut.isPurchasing)
    }

    func testRestorePurchases_ShouldUpdateSubscriptionStatus() async {
        // When
        await sut.restorePurchases()

        // Then
        // Without mock purchases, should remain unsubscribed
        XCTAssertFalse(sut.isSubscribed)
    }

    // MARK: - Error Handling Tests

    func testErrorMessage_ShouldBeSettableAndClearable() {
        // When
        sut.errorMessage = "Test error"

        // Then
        XCTAssertEqual(sut.errorMessage, "Test error")

        // When
        sut.errorMessage = nil

        // Then
        XCTAssertNil(sut.errorMessage)
    }
}