import XCTest
@testable import TreasuryPilot

final class TreasuryPilotTests: XCTestCase {

    // MARK: - Model Tests

    func testLegalEntityCreation() {
        let entity = LegalEntity(name: "Test Trust", entityType: .trust)
        XCTAssertEqual(entity.name, "Test Trust")
        XCTAssertEqual(entity.entityType, .trust)
        XCTAssertEqual(entity.costBasisMethod, .fifo)
        XCTAssertEqual(entity.taxTreatment, .taxable)
        XCTAssertEqual(entity.fiscalYearEnd, .december)
        XCTAssertNil(entity.parentEntityID)
    }

    func testEntityHierarchy() {
        let parent = LegalEntity(name: "Holding Trust", entityType: .trust)
        let child = LegalEntity(
            name: "LLC-A",
            entityType: .llc,
            parentEntityID: parent.id,
            ownershipPercentage: 60.0
        )
        XCTAssertEqual(child.parentEntityID, parent.id)
        XCTAssertEqual(child.ownershipPercentage, 60.0)
    }

    func testCustodialAccountCreation() {
        let entityID = UUID()
        let account = CustodialAccount(
            entityID: entityID,
            custodian: .coinbase,
            accountName: "Main Coinbase"
        )
        XCTAssertEqual(account.entityID, entityID)
        XCTAssertEqual(account.custodian, .coinbase)
        XCTAssertEqual(account.connectionStatus, .pending)
    }

    func testTransactionTotalValue() {
        let tx = CryptoTransaction(
            accountID: UUID(),
            entityID: UUID(),
            transactionType: .buy,
            asset: "BTC",
            quantity: 1.5,
            pricePerUnit: 30000.0,
            fee: 15.0
        )
        XCTAssertEqual(tx.totalValue, 45000.0)
    }

    // MARK: - Tax Lot Engine Tests

    func testCreateTaxLotFromBuy() {
        let tx = CryptoTransaction(
            accountID: UUID(),
            entityID: UUID(),
            transactionType: .buy,
            asset: "BTC",
            quantity: 2.0,
            pricePerUnit: 25000.0,
            fee: 10.0
        )
        let lot = TaxLotEngine.createTaxLot(from: tx)
        XCTAssertNotNil(lot)
        XCTAssertEqual(lot?.asset, "BTC")
        XCTAssertEqual(lot?.quantity, 2.0)
        XCTAssertEqual(lot?.costBasisPerUnit ?? 0, 25005.0, accuracy: 0.01)
    }

    func testCreateTaxLotFromSellReturnsNil() {
        let tx = CryptoTransaction(
            accountID: UUID(),
            entityID: UUID(),
            transactionType: .sell,
            asset: "BTC",
            quantity: 1.0,
            pricePerUnit: 30000.0
        )
        XCTAssertNil(TaxLotEngine.createTaxLot(from: tx))
    }

    func testFIFOLotSelection() {
        let entityID = UUID()
        let accountID = UUID()
        let lot1 = TaxLot(
            entityID: entityID, accountID: accountID, asset: "BTC",
            quantity: 1.0, costBasisPerUnit: 20000.0,
            acquisitionDate: Date(timeIntervalSinceNow: -86400 * 100),
            acquisitionTransactionID: UUID()
        )
        let lot2 = TaxLot(
            entityID: entityID, accountID: accountID, asset: "BTC",
            quantity: 1.0, costBasisPerUnit: 30000.0,
            acquisitionDate: Date(timeIntervalSinceNow: -86400 * 50),
            acquisitionTransactionID: UUID()
        )
        let selections = TaxLotEngine.selectLotsForDisposal(
            asset: "BTC", entityID: entityID, quantity: 0.5,
            lots: [lot1, lot2], method: .fifo
        )
        XCTAssertEqual(selections.count, 1)
        XCTAssertEqual(selections[0].0.id, lot1.id)
        XCTAssertEqual(selections[0].1, 0.5)
    }

    func testLIFOLotSelection() {
        let entityID = UUID()
        let accountID = UUID()
        let lot1 = TaxLot(
            entityID: entityID, accountID: accountID, asset: "ETH",
            quantity: 5.0, costBasisPerUnit: 1500.0,
            acquisitionDate: Date(timeIntervalSinceNow: -86400 * 100),
            acquisitionTransactionID: UUID()
        )
        let lot2 = TaxLot(
            entityID: entityID, accountID: accountID, asset: "ETH",
            quantity: 5.0, costBasisPerUnit: 2000.0,
            acquisitionDate: Date(timeIntervalSinceNow: -86400 * 10),
            acquisitionTransactionID: UUID()
        )
        let selections = TaxLotEngine.selectLotsForDisposal(
            asset: "ETH", entityID: entityID, quantity: 3.0,
            lots: [lot1, lot2], method: .lifo
        )
        XCTAssertEqual(selections.count, 1)
        XCTAssertEqual(selections[0].0.id, lot2.id)
    }

    func testHIFOLotSelection() {
        let entityID = UUID()
        let accountID = UUID()
        let lotLow = TaxLot(
            entityID: entityID, accountID: accountID, asset: "BTC",
            quantity: 1.0, costBasisPerUnit: 15000.0,
            acquisitionDate: Date(timeIntervalSinceNow: -86400 * 200),
            acquisitionTransactionID: UUID()
        )
        let lotHigh = TaxLot(
            entityID: entityID, accountID: accountID, asset: "BTC",
            quantity: 1.0, costBasisPerUnit: 50000.0,
            acquisitionDate: Date(timeIntervalSinceNow: -86400 * 50),
            acquisitionTransactionID: UUID()
        )
        let selections = TaxLotEngine.selectLotsForDisposal(
            asset: "BTC", entityID: entityID, quantity: 0.5,
            lots: [lotLow, lotHigh], method: .hifo
        )
        XCTAssertEqual(selections[0].0.id, lotHigh.id)
    }

    func testProcessSale() {
        let entityID = UUID()
        let accountID = UUID()
        var lots = [
            TaxLot(
                entityID: entityID, accountID: accountID, asset: "BTC",
                quantity: 2.0, costBasisPerUnit: 20000.0,
                acquisitionDate: Date(timeIntervalSinceNow: -86400 * 400),
                acquisitionTransactionID: UUID()
            )
        ]
        let saleTx = CryptoTransaction(
            accountID: accountID, entityID: entityID,
            transactionType: .sell, asset: "BTC",
            quantity: 1.0, pricePerUnit: 35000.0
        )
        let disposed = TaxLotEngine.processSale(transaction: saleTx, lots: &lots, method: .fifo)
        XCTAssertEqual(lots[0].quantity, 1.0)
        XCTAssertEqual(disposed.count, 1)
        XCTAssertEqual(disposed[0].gainLoss ?? 0, 15000.0, accuracy: 0.01)
    }

    // MARK: - Wash Sale Detection Tests

    func testWashSaleDetection() {
        let entityA = UUID()
        let entityB = UUID()
        let saleDate = Date()
        let buyDate = Calendar.current.date(byAdding: .day, value: 15, to: saleDate)!

        let saleTx = CryptoTransaction(
            accountID: UUID(), entityID: entityA,
            transactionType: .sell, asset: "BTC",
            quantity: 1.0, pricePerUnit: 20000.0, date: saleDate
        )
        let buyTx = CryptoTransaction(
            accountID: UUID(), entityID: entityB,
            transactionType: .buy, asset: "BTC",
            quantity: 1.0, pricePerUnit: 21000.0, date: buyDate
        )
        var disposedLot = TaxLot(
            entityID: entityA, accountID: UUID(), asset: "BTC",
            quantity: 1.0, costBasisPerUnit: 25000.0,
            acquisitionDate: Date(timeIntervalSinceNow: -86400 * 100),
            acquisitionTransactionID: UUID()
        )
        disposedLot.isDisposed = true
        disposedLot.disposalTransactionID = saleTx.id
        disposedLot.disposalDate = saleDate
        disposedLot.proceeds = 20000.0
        disposedLot.gainLoss = -5000.0

        let alerts = WashSaleDetector.detect(
            transactions: [saleTx, buyTx],
            lots: [disposedLot],
            relatedEntityIDs: Set([entityA, entityB])
        )
        XCTAssertEqual(alerts.count, 1)
        XCTAssertEqual(alerts[0].daysApart, 15)
        XCTAssertEqual(alerts[0].disallowedLoss, 5000.0, accuracy: 0.01)
    }

    func testNoWashSaleBeyond30Days() {
        let entityA = UUID()
        let saleDate = Date()
        let buyDate = Calendar.current.date(byAdding: .day, value: 35, to: saleDate)!

        let saleTx = CryptoTransaction(
            accountID: UUID(), entityID: entityA,
            transactionType: .sell, asset: "ETH",
            quantity: 10.0, pricePerUnit: 1500.0, date: saleDate
        )
        let buyTx = CryptoTransaction(
            accountID: UUID(), entityID: entityA,
            transactionType: .buy, asset: "ETH",
            quantity: 10.0, pricePerUnit: 1600.0, date: buyDate
        )
        var disposedLot = TaxLot(
            entityID: entityA, accountID: UUID(), asset: "ETH",
            quantity: 10.0, costBasisPerUnit: 2000.0,
            acquisitionDate: Date(timeIntervalSinceNow: -86400 * 200),
            acquisitionTransactionID: UUID()
        )
        disposedLot.isDisposed = true
        disposedLot.disposalTransactionID = saleTx.id
        disposedLot.disposalDate = saleDate
        disposedLot.proceeds = 15000.0
        disposedLot.gainLoss = -5000.0

        let alerts = WashSaleDetector.detect(
            transactions: [saleTx, buyTx],
            lots: [disposedLot],
            relatedEntityIDs: Set([entityA])
        )
        XCTAssertEqual(alerts.count, 0)
    }

    func testRelatedEntityIDs() {
        let parent = LegalEntity(name: "Parent", entityType: .trust)
        let child1 = LegalEntity(name: "LLC-A", entityType: .llc, parentEntityID: parent.id)
        let child2 = LegalEntity(name: "LLC-B", entityType: .llc, parentEntityID: parent.id)
        let unrelated = LegalEntity(name: "Unrelated", entityType: .individual)

        let related = WashSaleDetector.relatedEntityIDs(for: child1.id, entities: [parent, child1, child2, unrelated])
        XCTAssertTrue(related.contains(child1.id))
        XCTAssertTrue(related.contains(parent.id))
        XCTAssertTrue(related.contains(child2.id))
        XCTAssertFalse(related.contains(unrelated.id))
    }

    // MARK: - Quarterly Tax Calculator Tests

    func testEstimatedTaxCalculation() {
        let tax = QuarterlyTaxCalculator.estimatedTax(shortTerm: 10000.0, longTerm: 5000.0)
        XCTAssertEqual(tax, 5270.0, accuracy: 0.01)
    }

    func testEstimatedTaxWithLosses() {
        let tax = QuarterlyTaxCalculator.estimatedTax(shortTerm: -5000.0, longTerm: -3000.0)
        XCTAssertEqual(tax, 0.0, accuracy: 0.01)
    }

    // MARK: - Form 8949 Export Tests

    func testCSVGeneration() {
        let rows = [
            Form8949Exporter.Form8949Row(
                description: "1.5 BTC",
                dateAcquired: "01/15/2025",
                dateSold: "06/20/2025",
                proceeds: 52500.0,
                costBasis: 37500.0,
                gainOrLoss: 15000.0,
                holdingPeriod: "Short-Term",
                washSaleDisallowed: 0.0
            )
        ]
        let csv = Form8949Exporter.generateCSV(rows: rows)
        XCTAssertTrue(csv.contains("Description,Date Acquired"))
        XCTAssertTrue(csv.contains("1.5 BTC"))
        XCTAssertTrue(csv.contains("52500.00"))
    }

    // MARK: - StoreManager Tests

    func testStoreManagerInitialState() {
        let manager = StoreManager()
        XCTAssertFalse(manager.isSubscribed)
        XCTAssertTrue(manager.products.isEmpty)
        XCTAssertNil(manager.activeSubscription)
        XCTAssertEqual(manager.currentTier, .free)
    }

    func testProductIdentifiersAreUnique() {
        XCTAssertEqual(StoreManager.allProductIDs.count, 3)
    }

    func testTierLimits() {
        XCTAssertEqual(SubscriptionTier.free.maxEntities, 1)
        XCTAssertEqual(SubscriptionTier.professional.maxEntities, 3)
        XCTAssertEqual(SubscriptionTier.familyOffice.maxEntities, 10)
        XCTAssertFalse(SubscriptionTier.free.canExport)
        XCTAssertTrue(SubscriptionTier.professional.canExport)
        XCTAssertTrue(SubscriptionTier.familyOffice.hasWashSaleDetection)
    }

    // MARK: - Report Generator Tests

    func testConsolidatedReport() {
        let entity = LegalEntity(name: "Test LLC", entityType: .llc)
        let account = CustodialAccount(entityID: entity.id, custodian: .coinbase, accountName: "Main")
        let lot = TaxLot(
            entityID: entity.id, accountID: account.id, asset: "BTC",
            quantity: 1.0, costBasisPerUnit: 30000.0,
            acquisitionDate: Date(), acquisitionTransactionID: UUID()
        )
        let report = ReportGenerator.generateConsolidated(
            entities: [entity], accounts: [account], lots: [lot],
            washSaleAlerts: [], taxYear: 2026
        )
        XCTAssertEqual(report.entities.count, 1)
        XCTAssertEqual(report.totalHoldings.count, 1)
        XCTAssertEqual(report.totalHoldings[0].asset, "BTC")

        let text = ReportGenerator.generateTextReport(report)
        XCTAssertTrue(text.contains("TREASURYPILOT"))
        XCTAssertTrue(text.contains("Test LLC"))
    }

    // MARK: - User Role Tests

    func testAccessRolePermissions() {
        XCTAssertTrue(AccessRole.owner.canEdit)
        XCTAssertTrue(AccessRole.owner.canDelete)
        XCTAssertTrue(AccessRole.owner.canInvite)
        XCTAssertTrue(AccessRole.admin.canEdit)
        XCTAssertFalse(AccessRole.admin.canDelete)
        XCTAssertFalse(AccessRole.readOnly.canEdit)
    }
}
