import Foundation

struct QuarterlyTaxCalculator {
    static let federalShortTermRate = 0.37
    static let federalLongTermRate = 0.20
    static let niitRate = 0.038

    static func calculate(transactions: [CryptoTransaction], lots: [TaxLot],
                          entityID: UUID, taxYear: Int, quarter: Quarter) -> QuarterlyEstimate {
        let disposed = lots.filter {
            $0.isDisposed && $0.entityID == entityID &&
            Calendar.current.component(.year, from: $0.disposalDate ?? Date()) == taxYear
        }

        var stGains = 0.0, ltGains = 0.0
        for lot in disposed {
            guard let gain = lot.gainLoss else { continue }
            if lot.holdingPeriod == .shortTerm { stGains += gain }
            else { ltGains += gain }
        }

        return QuarterlyEstimate(entityID: entityID, taxYear: taxYear, quarter: quarter,
                                 shortTermGains: stGains, longTermGains: ltGains)
    }

    static func deadlines(for taxYear: Int) -> [(Quarter, Date)] {
        let cal = Calendar.current
        return [
            (.q1, cal.date(from: DateComponents(year: taxYear, month: 4, day: 15))!),
            (.q2, cal.date(from: DateComponents(year: taxYear, month: 6, day: 15))!),
            (.q3, cal.date(from: DateComponents(year: taxYear, month: 9, day: 15))!),
            (.q4, cal.date(from: DateComponents(year: taxYear + 1, month: 1, day: 15))!)
        ]
    }
}
