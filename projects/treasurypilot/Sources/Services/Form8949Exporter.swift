import Foundation

struct Form8949Exporter {

    struct Form8949Row: Codable {
        let description: String // e.g., "1.5 BTC"
        let dateAcquired: String
        let dateSold: String
        let proceeds: Double
        let costBasis: Double
        let gainOrLoss: Double
        let holdingPeriod: String // "Short-Term" or "Long-Term"
        let washSaleDisallowed: Double
    }

    static func generateRows(
        lots: [TaxLot],
        entityID: UUID,
        taxYear: Int,
        washSaleAlerts: [WashSaleAlert]
    ) -> [Form8949Row] {
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: DateComponents(year: taxYear, month: 1, day: 1))!
        let endOfYear = calendar.date(from: DateComponents(year: taxYear, month: 12, day: 31, hour: 23, minute: 59, second: 59))!

        let disposed = lots.filter { lot in
            lot.entityID == entityID &&
            lot.isDisposed &&
            lot.disposalDate != nil &&
            lot.disposalDate! >= startOfYear &&
            lot.disposalDate! <= endOfYear
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"

        return disposed.map { lot in
            let washSaleAmount = washSaleAlerts
                .filter { $0.saleEntityID == entityID && $0.asset == lot.asset }
                .reduce(0.0) { $0 + $1.disallowedLoss }

            return Form8949Row(
                description: "\(lot.originalQuantity) \(lot.asset)",
                dateAcquired: dateFormatter.string(from: lot.acquisitionDate),
                dateSold: dateFormatter.string(from: lot.disposalDate ?? Date()),
                proceeds: lot.proceeds ?? 0,
                costBasis: lot.totalCostBasis,
                gainOrLoss: lot.gainLoss ?? 0,
                holdingPeriod: lot.holdingPeriod.rawValue,
                washSaleDisallowed: washSaleAmount
            )
        }
    }

    static func generateCSV(rows: [Form8949Row]) -> String {
        var csv = "Description,Date Acquired,Date Sold,Proceeds,Cost Basis,Gain or Loss,Holding Period,Wash Sale Disallowed\n"

        for row in rows {
            csv += "\"\(row.description)\","
            csv += "\(row.dateAcquired),"
            csv += "\(row.dateSold),"
            csv += String(format: "%.2f", row.proceeds) + ","
            csv += String(format: "%.2f", row.costBasis) + ","
            csv += String(format: "%.2f", row.gainOrLoss) + ","
            csv += "\(row.holdingPeriod),"
            csv += String(format: "%.2f", row.washSaleDisallowed)
            csv += "\n"
        }

        return csv
    }

    static func exportToFile(
        lots: [TaxLot],
        entityID: UUID,
        entityName: String,
        taxYear: Int,
        washSaleAlerts: [WashSaleAlert]
    ) throws -> URL {
        let rows = generateRows(lots: lots, entityID: entityID, taxYear: taxYear, washSaleAlerts: washSaleAlerts)
        let csv = generateCSV(rows: rows)

        let filename = "Form8949_\(entityName.replacingOccurrences(of: " ", with: "_"))_\(taxYear).csv"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)

        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
