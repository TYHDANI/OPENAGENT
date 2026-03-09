import Foundation

struct QuarterlyTaxCalculator {

    // Federal short-term capital gains rate (treated as ordinary income, use highest bracket estimate)
    static let shortTermRate: Double = 0.37
    // Federal long-term capital gains rate (highest bracket)
    static let longTermRate: Double = 0.20
    // Net investment income tax
    static let niitRate: Double = 0.038

    static func calculateEstimate(
        entityID: UUID,
        taxYear: Int,
        quarter: TaxQuarter,
        lots: [TaxLot]
    ) -> QuarterlyEstimate {
        let (startOfYear, quarterEnd) = dateRange(taxYear: taxYear, quarter: quarter)

        // Quarter-specific gains
        let quarterStart = quarterStartDate(taxYear: taxYear, quarter: quarter)
        let quarterGains = TaxLotEngine.realizedGains(
            lots: lots,
            entityID: entityID,
            from: quarterStart,
            to: quarterEnd
        )

        // YTD gains
        let ytdGains = TaxLotEngine.realizedGains(
            lots: lots,
            entityID: entityID,
            from: startOfYear,
            to: quarterEnd
        )

        let quarterTax = estimatedTax(shortTerm: quarterGains.shortTerm, longTerm: quarterGains.longTerm)
        let ytdTax = estimatedTax(shortTerm: ytdGains.shortTerm, longTerm: ytdGains.longTerm)

        return QuarterlyEstimate(
            entityID: entityID,
            taxYear: taxYear,
            quarter: quarter,
            shortTermGains: quarterGains.shortTerm,
            longTermGains: quarterGains.longTerm,
            estimatedTaxOwed: quarterTax,
            ytdRealizedGains: ytdGains.shortTerm + ytdGains.longTerm,
            ytdEstimatedTax: ytdTax
        )
    }

    static func estimatedTax(shortTerm: Double, longTerm: Double) -> Double {
        let stTax = max(0, shortTerm) * shortTermRate
        let ltTax = max(0, longTerm) * longTermRate
        let niit = max(0, shortTerm + longTerm) * niitRate
        return stTax + ltTax + niit
    }

    static func calculateAllQuarters(
        entityID: UUID,
        taxYear: Int,
        lots: [TaxLot]
    ) -> [QuarterlyEstimate] {
        TaxQuarter.allCases.map { quarter in
            calculateEstimate(entityID: entityID, taxYear: taxYear, quarter: quarter, lots: lots)
        }
    }

    // MARK: - Date helpers

    private static func dateRange(taxYear: Int, quarter: TaxQuarter) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: DateComponents(year: taxYear, month: 1, day: 1))!
        let end = quarterEndDate(taxYear: taxYear, quarter: quarter)
        return (startOfYear, end)
    }

    private static func quarterStartDate(taxYear: Int, quarter: TaxQuarter) -> Date {
        let calendar = Calendar.current
        let month: Int
        switch quarter {
        case .q1: month = 1
        case .q2: month = 4
        case .q3: month = 7
        case .q4: month = 10
        }
        return calendar.date(from: DateComponents(year: taxYear, month: month, day: 1))!
    }

    private static func quarterEndDate(taxYear: Int, quarter: TaxQuarter) -> Date {
        let calendar = Calendar.current
        let month: Int
        let day: Int
        switch quarter {
        case .q1: month = 3; day = 31
        case .q2: month = 6; day = 30
        case .q3: month = 9; day = 30
        case .q4: month = 12; day = 31
        }
        return calendar.date(from: DateComponents(year: taxYear, month: month, day: day, hour: 23, minute: 59, second: 59))!
    }
}
