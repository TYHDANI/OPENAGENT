import Foundation

enum CostBasisStrategy: String, Codable, CaseIterable {
    case fifo = "FIFO", lifo = "LIFO", hifo = "HIFO", specificID = "Specific ID"
}

struct DisposalResult {
    var lotsUsed: [(lot: TaxLot, quantityUsed: Double)]
    var totalCostBasis: Double
    var totalProceeds: Double
    var gainLoss: Double
    var shortTermGain: Double
    var longTermGain: Double
}

struct TaxLotEngine {
    static func dispose(asset: String, quantity: Double, proceeds: Double,
                        lots: [TaxLot], strategy: CostBasisStrategy, date: Date = Date()) -> DisposalResult {
        var available = lots.filter { $0.asset == asset && !$0.isDisposed && $0.quantity > 0 }
        switch strategy {
        case .fifo: available.sort { $0.acquisitionDate < $1.acquisitionDate }
        case .lifo: available.sort { $0.acquisitionDate > $1.acquisitionDate }
        case .hifo: available.sort { $0.costBasisPerUnit > $1.costBasisPerUnit }
        case .specificID: break
        }

        var remaining = quantity
        var usedLots: [(lot: TaxLot, quantityUsed: Double)] = []
        var totalBasis = 0.0

        for lot in available {
            guard remaining > 0 else { break }
            let used = min(lot.quantity, remaining)
            totalBasis += used * lot.costBasisPerUnit
            usedLots.append((lot: lot, quantityUsed: used))
            remaining -= used
        }

        let pricePerUnit = quantity > 0 ? proceeds / quantity : 0
        var stGain = 0.0, ltGain = 0.0
        for (lot, qty) in usedLots {
            let gain = (pricePerUnit - lot.costBasisPerUnit) * qty
            let days = Calendar.current.dateComponents([.day], from: lot.acquisitionDate, to: date).day ?? 0
            if days > 365 { ltGain += gain } else { stGain += gain }
        }

        return DisposalResult(lotsUsed: usedLots, totalCostBasis: totalBasis,
                              totalProceeds: proceeds, gainLoss: proceeds - totalBasis,
                              shortTermGain: stGain, longTermGain: ltGain)
    }
}
