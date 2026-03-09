import XCTest
@testable import LegacyVault

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

    // MARK: - Account Model Tests

    func testAccountCreation() {
        let account = Account(
            platform: .coinbase,
            nickname: "My Coinbase",
            connectionType: .apiKey
        )
        XCTAssertEqual(account.platform, .coinbase)
        XCTAssertEqual(account.nickname, "My Coinbase")
        XCTAssertEqual(account.connectionType, .apiKey)
        XCTAssertFalse(account.isConnected)
        XCTAssertEqual(account.totalValueUSD, 0)
        XCTAssertEqual(account.dormancyStatus, .unknown)
    }

    func testAccountDefaultNickname() {
        let account = Account(
            platform: .kraken,
            connectionType: .apiKey
        )
        XCTAssertEqual(account.nickname, "Kraken")
    }

    func testExchangePlatformProperties() {
        XCTAssertTrue(ExchangePlatform.coinbase.isExchange)
        XCTAssertTrue(ExchangePlatform.kraken.isExchange)
        XCTAssertFalse(ExchangePlatform.ethWallet.isExchange)
        XCTAssertFalse(ExchangePlatform.btcWallet.isExchange)
        XCTAssertFalse(ExchangePlatform.solWallet.isExchange)
    }

    // MARK: - Beneficiary Model Tests

    func testBeneficiaryCreation() {
        let beneficiary = Beneficiary(
            name: "Jane Doe",
            email: "jane@example.com",
            phone: "555-0123",
            relationship: .spouse
        )
        XCTAssertEqual(beneficiary.name, "Jane Doe")
        XCTAssertEqual(beneficiary.email, "jane@example.com")
        XCTAssertEqual(beneficiary.relationship, .spouse)
        XCTAssertEqual(beneficiary.verificationStatus, .unverified)
        XCTAssertTrue(beneficiary.allocations.isEmpty)
    }

    func testRelationshipDisplayNames() {
        XCTAssertEqual(Relationship.spouse.displayName, "Spouse")
        XCTAssertEqual(Relationship.child.displayName, "Child")
        XCTAssertEqual(Relationship.attorney.displayName, "Attorney")
        XCTAssertEqual(Relationship.trustee.displayName, "Trustee")
    }

    // MARK: - Succession Plan Tests

    func testSuccessionPlanCreation() {
        let plan = SuccessionPlan(
            name: "My Estate Plan",
            status: .draft
        )
        XCTAssertEqual(plan.name, "My Estate Plan")
        XCTAssertEqual(plan.status, .draft)
        XCTAssertTrue(plan.beneficiaryIDs.isEmpty)
        XCTAssertTrue(plan.triggerConditions.isEmpty)
        XCTAssertTrue(plan.trustedContacts.isEmpty)
    }

    func testTriggerConditionDefaults() {
        let dormancy = TriggerCondition(type: .dormancy)
        XCTAssertEqual(dormancy.dormancyDays, 90)
        XCTAssertTrue(dormancy.isEnabled)

        let deadMan = TriggerCondition(type: .deadManSwitch)
        XCTAssertEqual(deadMan.checkInInterval, .monthly)
        XCTAssertTrue(deadMan.isEnabled)
    }

    func testCheckInIntervalDays() {
        XCTAssertEqual(CheckInInterval.weekly.days, 7)
        XCTAssertEqual(CheckInInterval.biweekly.days, 14)
        XCTAssertEqual(CheckInInterval.monthly.days, 30)
        XCTAssertEqual(CheckInInterval.quarterly.days, 90)
    }

    // MARK: - Subscription Tier Tests

    func testSubscriptionTierLimits() {
        XCTAssertEqual(SubscriptionTier.free.maxAccounts, 2)
        XCTAssertEqual(SubscriptionTier.free.maxBeneficiaries, 1)
        XCTAssertEqual(SubscriptionTier.guardian.maxAccounts, 10)
        XCTAssertEqual(SubscriptionTier.guardian.maxBeneficiaries, 5)
        XCTAssertEqual(SubscriptionTier.estate.maxAccounts, .max)
        XCTAssertEqual(SubscriptionTier.familyOffice.maxAccounts, .max)
    }

    func testSubscriptionTierFeatures() {
        XCTAssertFalse(SubscriptionTier.free.features.isEmpty)
        XCTAssertFalse(SubscriptionTier.guardian.features.isEmpty)
        XCTAssertFalse(SubscriptionTier.estate.features.isEmpty)
        XCTAssertFalse(SubscriptionTier.familyOffice.features.isEmpty)
    }

    // MARK: - Holding Model Tests

    func testHoldingCreation() {
        let holding = Holding(
            symbol: "BTC",
            name: "Bitcoin",
            quantity: 1.5,
            valueUSD: 150000.0,
            priceUSD: 100000.0
        )
        XCTAssertEqual(holding.symbol, "BTC")
        XCTAssertEqual(holding.quantity, 1.5)
        XCTAssertEqual(holding.valueUSD, 150000.0)
        XCTAssertEqual(holding.changePercent24h, 0)
    }

    // MARK: - Transaction Model Tests

    func testTransactionCreation() {
        let tx = ActivityTransaction(
            accountID: UUID(),
            platform: .coinbase,
            type: .buy,
            asset: "ETH",
            amount: 10.0,
            valueUSD: 35000.0
        )
        XCTAssertEqual(tx.platform, .coinbase)
        XCTAssertEqual(tx.type, .buy)
        XCTAssertEqual(tx.asset, "ETH")
        XCTAssertEqual(tx.anomalyLevel, .none)
        XCTAssertNil(tx.anomalyReason)
    }

    // MARK: - DashboardViewModel Tests

    func testDashboardViewModelInitialState() {
        let vm = DashboardViewModel()
        XCTAssertTrue(vm.accounts.isEmpty)
        XCTAssertEqual(vm.totalEstateValue, 0)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    func testDashboardAllocationsByAssetEmpty() {
        let vm = DashboardViewModel()
        XCTAssertTrue(vm.allocationsByAsset.isEmpty)
    }

    // MARK: - AccountsViewModel Tests

    func testAccountsViewModelInitialState() {
        let vm = AccountsViewModel()
        XCTAssertTrue(vm.accounts.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertFalse(vm.showingAddAccount)
        XCTAssertEqual(vm.selectedPlatform, .coinbase)
    }

    func testAccountsViewModelValidation() async {
        let vm = AccountsViewModel()
        vm.selectedPlatform = .coinbase
        vm.apiKey = ""
        let result = await vm.addAccount()
        XCTAssertFalse(result, "Should fail with empty API key")
        XCTAssertNotNil(vm.errorMessage)
    }

    func testAccountsViewModelWalletValidation() async {
        let vm = AccountsViewModel()
        vm.selectedPlatform = .ethWallet
        vm.walletAddress = ""
        let result = await vm.addAccount()
        XCTAssertFalse(result, "Should fail with empty wallet address")
        XCTAssertNotNil(vm.errorMessage)
    }

    // MARK: - BeneficiaryViewModel Tests

    func testBeneficiaryViewModelValidation() async {
        let vm = BeneficiaryViewModel()
        vm.name = ""
        vm.email = "test@example.com"
        let result = await vm.saveBeneficiary()
        XCTAssertFalse(result, "Should fail with empty name")
    }

    func testBeneficiaryViewModelEmailValidation() async {
        let vm = BeneficiaryViewModel()
        vm.name = "Test"
        vm.email = ""
        let result = await vm.saveBeneficiary()
        XCTAssertFalse(result, "Should fail with empty email")
    }

    func testBeneficiaryFormReset() {
        let vm = BeneficiaryViewModel()
        vm.name = "Test"
        vm.email = "test@test.com"
        vm.phone = "555"
        vm.resetForm()
        XCTAssertEqual(vm.name, "")
        XCTAssertEqual(vm.email, "")
        XCTAssertEqual(vm.phone, "")
        XCTAssertNil(vm.editingBeneficiary)
    }

    // MARK: - SuccessionPlanViewModel Tests

    func testSuccessionPlanViewModelInitialState() {
        let vm = SuccessionPlanViewModel()
        XCTAssertTrue(vm.plans.isEmpty)
        XCTAssertNil(vm.currentPlan)
        XCTAssertEqual(vm.builderStep, 0)
        XCTAssertEqual(vm.totalBuilderSteps, 4)
        XCTAssertTrue(vm.enableDormancy)
        XCTAssertTrue(vm.enableDeadManSwitch)
    }

    // MARK: - DeadManSwitchViewModel Tests

    func testDeadManSwitchInitialState() {
        let vm = DeadManSwitchViewModel()
        XCTAssertFalse(vm.isEnabled)
        XCTAssertEqual(vm.checkInInterval, .monthly)
        XCTAssertNil(vm.lastCheckInDate)
        XCTAssertEqual(vm.missedCheckIns, 0)
        XCTAssertFalse(vm.isOverdue)
    }

    func testDeadManSwitchDisabledStatus() {
        let vm = DeadManSwitchViewModel()
        vm.isEnabled = false
        XCTAssertEqual(vm.daysUntilNextCheckIn, 0)
    }

    // MARK: - ActivityViewModel Tests

    func testActivityViewModelFilters() {
        let vm = ActivityViewModel()
        XCTAssertEqual(vm.selectedDateRange, .all)
        XCTAssertNil(vm.selectedPlatform)
        XCTAssertNil(vm.selectedAsset)
        XCTAssertTrue(vm.filteredTransactions.isEmpty)
        XCTAssertTrue(vm.anomalies.isEmpty)
    }

    // MARK: - SettingsViewModel Tests

    func testSettingsViewModelInitialState() {
        let vm = SettingsViewModel()
        XCTAssertFalse(vm.notificationsEnabled)
        XCTAssertTrue(vm.dormancyAlertsEnabled)
        XCTAssertTrue(vm.securityAlertsEnabled)
        XCTAssertEqual(vm.currentTier, .free)
    }
}
