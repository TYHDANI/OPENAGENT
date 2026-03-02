import XCTest
@testable import {{APP_NAME}}

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

    // MARK: - Placeholder

    func testPlaceholder() {
        // TODO: Add feature-specific tests once the build agent generates screens.
        XCTAssertTrue(true, "Placeholder test — replace with real tests")
    }
}
