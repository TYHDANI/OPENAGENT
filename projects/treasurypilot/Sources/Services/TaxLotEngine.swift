import Foundation

struct TaxLotEngine {

    // MARK: - Create tax lots from buy transactions

    static func createTaxLot(from transaction: CryptoTransaction) -> TaxLot? {
        guard transaction.transactionType == .buy || transaction.transactionType == .income else {
            return nil
        }
        return TaxLot(
            entityID: transaction.entityID,
            accountID: transaction.accountID,
            asset: transaction.asset,
            quantity: transaction.quantity,
            costBasisPerUnit: transaction.pricePerUnit + (transaction.fee / max(transaction.quantity, 0.00000001)),
            acquisitionDate: transaction.date,
            acquisitionTransactionID: transaction.id
        )
    }

    // MARK: - Select lots for disposal based on cost-basis method

    static func selectLotsForDisposal(
        asset: String,
        entityID: UUID,
        quantity: Double,
        lots: [TaxLot],
        method: CostBasisMethod
    ) -> [(TaxLot, Double)] {
        // Filter to matching open lots for this entity and asset
        let available = lots
            .filter { $0.entityID == entityID && $0.asset == asset && !$0.isDisposed && $0.quantity > 0 }

        let sorted: [TaxLot]
        switch method {
        case .fifo:
            sorted = available.sorted { $0.acquisitionDate < $1.acquisitionDate }
        case .lifo:
            sorted = available.sorted { $0.acquisitionDate > $1.acquisitionDate }
        case .hifo:
            sorted = available.sorted { $0.costBasisPerUnit > $1.costBasisPerUnit }
        case .specificId:
            // Default to FIFO for automatic selection; user can override
            sorted = available.sorted { $0.acquisitionDate < $1.acquisitionDate }
        }

        var remaining = quantity
        var selections: [(TaxLot, Double)] = []

        for lot in sorted {
            guard remaining > 0 else { break }
            let takeQty = min(lot.quantity, remaining)
            selections.append((lot, takeQty))
            remaining -= takeQty
        }

        return selections
    }

    // MARK: - Process a sale transaction

    static func processSale(
        transaction: CryptoTransaction,
        lots: inout [TaxLot],
        method: CostBasisMethod
    ) -> [TaxLot] {
        guard transaction.transactionType == .sell else { return [] }

        let selections = selectLotsForDisposal(
            asset: transaction.asset,
            entityID: transaction.entityID,
            quantity: transaction.quantity,
            lots: lots,
            method: method
        )

        var disposedLots: [TaxLot] = []

        for (lot, qty) in selections {
            guard let index = lots.firstIndex(where: { $0.id == lot.id }) else { continue }

            let proceeds = qty * transaction.pricePerUnit
            let costBasis = qty * lot.costBasisPerUnit
            let gainLoss = proceeds - costBasis

            if qty >= lots[index].quantity {
                // Full disposal
                lots[index].quantity = 0
                lots[index].isDisposed = true
                lots[index].disposalDate = transaction.date
                lots[index].disposalTransactionID = transaction.id
                lots[index].proceeds = proceeds
                lots[index].gainLoss = gainLoss
            } else {
                // Partial disposal — create a new disposed lot for the sold portion
                var disposedLot = lots[index]
                disposedLot.quantity = qty
                disposedLot.isDisposed = true
                disposedLot.disposalDate = transaction.date
                disposedLot.disposalTransactionID = transaction.id
                disposedLot.proceeds = proceeds
                disposedLot.gainLoss = gainLoss
                disposedLots.append(disposedLot)

                // Reduce original lot
                lots[index].quantity -= qty
            }

            // Update holding period
            let oneYearLater = Calendar.current.date(byAdding: .year, value: 1, to: lot.acquisitionDate) ?? lot.acquisitionDate
            lots[index].holdingPeriod = transaction.date >= oneYearLater ? .longTerm : .shortTerm
        }

        return disposedLots
    }

    // MARK: - Calculate realized gains for a period

    static func realizedGains(
        lots: [TaxLot],
        entityID: UUID?,
        from startDate: Date,
        to endDate: Date
    ) -> (shortTerm: Double, longTerm: Double) {
        let disposed = lots.filter { lot in
            lot.isDisposed &&
            (entityID == nil || lot.entityID == entityID) &&
            lot.disposalDate != nil &&
            lot.disposalDate! >= startDate &&
            lot.disposalDate! <= endDate
        }

        let shortTerm = disposed
            .filter { $0.holdingPeriod == .shortTerm }
            .compactMap(\.gainLoss)
            .reduce(0, +)

        let longTerm = disposed
            .filter { $0.holdingPeriod == .longTerm }
            .compactMap(\.gainLoss)
            .reduce(0, +)

        return (shortTerm, longTerm)
    }
}
