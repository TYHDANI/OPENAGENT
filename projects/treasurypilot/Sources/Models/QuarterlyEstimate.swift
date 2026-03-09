import Foundation

enum TaxQuarter: String, Codable, CaseIterable, Identifiable {
    case q1 = "Q1"
    case q2 = "Q2"
    case q3 = "Q3"
    case q4 = "Q4"

    var id: String { rawValue }

    var dateRange: String {
        switch self {
        case .q1: return "Jan 1 – Mar 31"
        case .q2: return "Apr 1 – Jun 30"
        case .q3: return "Jul 1 – Sep 30"
        case .q4: return "Oct 1 – Dec 31"
        }
    }

    var estimatedPaymentDeadline: String {
        switch self {
        case .q1: return "April 15"
        case .q2: return "June 15"
        case .q3: return "September 15"
        case .q4: return "January 15 (next year)"
        }
    }
}

struct QuarterlyEstimate: Identifiable, Codable, Hashable {
    let id: UUID
    var entityID: UUID
    var taxYear: Int
    var quarter: TaxQuarter
    var shortTermGains: Double
    var longTermGains: Double
    var totalRealizedGains: Double
    var estimatedTaxOwed: Double
    var ytdRealizedGains: Double
    var ytdEstimatedTax: Double
    var calculatedAt: Date

    init(
        id: UUID = UUID(),
        entityID: UUID,
        taxYear: Int,
        quarter: TaxQuarter,
        shortTermGains: Double,
        longTermGains: Double,
        estimatedTaxOwed: Double,
        ytdRealizedGains: Double,
        ytdEstimatedTax: Double,
        calculatedAt: Date = Date()
    ) {
        self.id = id
        self.entityID = entityID
        self.taxYear = taxYear
        self.quarter = quarter
        self.shortTermGains = shortTermGains
        self.longTermGains = longTermGains
        self.totalRealizedGains = shortTermGains + longTermGains
        self.estimatedTaxOwed = estimatedTaxOwed
        self.ytdRealizedGains = ytdRealizedGains
        self.ytdEstimatedTax = ytdEstimatedTax
        self.calculatedAt = calculatedAt
    }
}
