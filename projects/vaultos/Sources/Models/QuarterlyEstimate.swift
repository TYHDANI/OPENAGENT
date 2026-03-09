import Foundation

enum Quarter: String, Codable, CaseIterable { case q1 = "Q1", q2 = "Q2", q3 = "Q3", q4 = "Q4" }

struct QuarterlyEstimate: Identifiable, Codable {
    let id: UUID
    var entityID: UUID
    var taxYear: Int
    var quarter: Quarter
    var shortTermGains: Double
    var longTermGains: Double
    var totalRealizedGains: Double
    var estimatedTaxOwed: Double
    var ytdRealizedGains: Double
    var ytdEstimatedTax: Double
    var calculatedAt: Date

    init(id: UUID = UUID(), entityID: UUID, taxYear: Int, quarter: Quarter,
         shortTermGains: Double = 0, longTermGains: Double = 0) {
        self.id = id; self.entityID = entityID; self.taxYear = taxYear; self.quarter = quarter
        self.shortTermGains = shortTermGains; self.longTermGains = longTermGains
        self.totalRealizedGains = shortTermGains + longTermGains
        self.estimatedTaxOwed = (shortTermGains * 0.37) + (longTermGains * 0.20) + ((shortTermGains + longTermGains) * 0.038)
        self.ytdRealizedGains = shortTermGains + longTermGains
        self.ytdEstimatedTax = self.estimatedTaxOwed
        self.calculatedAt = Date()
    }
}
