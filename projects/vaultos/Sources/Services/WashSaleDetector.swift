import Foundation

struct WashSaleDetector {
    static func detect(transactions: [CryptoTransaction], entities: [LegalEntity]) -> [WashSaleAlert] {
        var alerts: [WashSaleAlert] = []
        let sales = transactions.filter { $0.transactionType == .sell }
        let buys = transactions.filter { $0.transactionType == .buy }

        for sale in sales {
            let saleLoss = sale.totalValue - (sale.quantity * sale.pricePerUnit)
            guard saleLoss < 0 else { continue }

            for buy in buys {
                guard buy.asset == sale.asset else { continue }
                guard buy.id != sale.id else { continue }

                let daysBetween = abs(Calendar.current.dateComponents([.day], from: sale.date, to: buy.date).day ?? 0)
                guard daysBetween <= 30 else { continue }

                let alert = WashSaleAlert(
                    saleTransactionID: sale.id,
                    buyTransactionID: buy.id,
                    saleEntityID: sale.entityID,
                    buyEntityID: buy.entityID,
                    asset: sale.asset,
                    saleDate: sale.date,
                    buyDate: buy.date,
                    disallowedLoss: abs(saleLoss),
                    daysApart: daysBetween
                )
                alerts.append(alert)
            }
        }
        return alerts
    }
}
