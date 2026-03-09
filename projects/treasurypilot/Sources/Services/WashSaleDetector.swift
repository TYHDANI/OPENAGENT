import Foundation

struct WashSaleDetector {

    static let washSaleWindow: TimeInterval = 30 * 24 * 60 * 60 // 30 days in seconds

    /// Detect wash sales across related entities.
    /// A wash sale occurs when a security is sold at a loss and a substantially identical
    /// security is purchased within 30 days before or after the sale.
    static func detect(
        transactions: [CryptoTransaction],
        lots: [TaxLot],
        relatedEntityIDs: Set<UUID>
    ) -> [WashSaleAlert] {
        var alerts: [WashSaleAlert] = []

        // Find all sell transactions at a loss for related entities
        let sales = transactions.filter { tx in
            tx.transactionType == .sell && relatedEntityIDs.contains(tx.entityID)
        }

        let buys = transactions.filter { tx in
            (tx.transactionType == .buy || tx.transactionType == .income) &&
            relatedEntityIDs.contains(tx.entityID)
        }

        for sale in sales {
            // Find the disposed lot(s) for this sale to determine if there was a loss
            let disposedLots = lots.filter { lot in
                lot.disposalTransactionID == sale.id && lot.isDisposed
            }

            let totalLoss = disposedLots.compactMap(\.gainLoss).reduce(0, +)
            guard totalLoss < 0 else { continue } // Only check sales at a loss

            // Check for offsetting buys within 30-day window (before or after)
            for buy in buys {
                guard buy.asset == sale.asset else { continue }
                guard buy.id != sale.id else { continue }

                let daysBetween = Calendar.current.dateComponents(
                    [.day],
                    from: min(sale.date, buy.date),
                    to: max(sale.date, buy.date)
                ).day ?? 0

                if daysBetween <= 30 {
                    let alert = WashSaleAlert(
                        saleTransactionID: sale.id,
                        buyTransactionID: buy.id,
                        saleEntityID: sale.entityID,
                        buyEntityID: buy.entityID,
                        asset: sale.asset,
                        saleDate: sale.date,
                        buyDate: buy.date,
                        disallowedLoss: abs(totalLoss),
                        daysApart: daysBetween
                    )
                    alerts.append(alert)
                }
            }
        }

        return alerts
    }

    /// Get all entity IDs that are related (under common control).
    /// For now, entities sharing a parent or being siblings are considered related.
    static func relatedEntityIDs(for entityID: UUID, entities: [LegalEntity]) -> Set<UUID> {
        var related = Set<UUID>([entityID])

        guard let entity = entities.first(where: { $0.id == entityID }) else {
            return related
        }

        // If this entity has a parent, include the parent and all siblings
        if let parentID = entity.parentEntityID {
            related.insert(parentID)
            for sibling in entities where sibling.parentEntityID == parentID {
                related.insert(sibling.id)
            }
        }

        // Include all children of this entity
        for child in entities where child.parentEntityID == entityID {
            related.insert(child.id)
        }

        return related
    }
}
