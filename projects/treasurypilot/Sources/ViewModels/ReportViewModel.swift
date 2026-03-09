import Foundation
import SwiftUI

@Observable
@MainActor
final class ReportViewModel {
    var consolidatedReport: ReportGenerator.ConsolidatedReport?
    var form8949Rows: [Form8949Exporter.Form8949Row] = []
    var exportedFileURL: URL?
    var reportText: String = ""
    var errorMessage: String?
    var isGenerating = false
    var selectedTaxYear: Int = Calendar.current.component(.year, from: Date())

    func generateConsolidatedReport(
        entities: [LegalEntity],
        accounts: [CustodialAccount],
        lots: [TaxLot],
        washSaleAlerts: [WashSaleAlert]
    ) {
        isGenerating = true
        defer { isGenerating = false }

        let report = ReportGenerator.generateConsolidated(
            entities: entities,
            accounts: accounts,
            lots: lots,
            washSaleAlerts: washSaleAlerts,
            taxYear: selectedTaxYear
        )

        consolidatedReport = report
        reportText = ReportGenerator.generateTextReport(report)
    }

    func generateForm8949(
        lots: [TaxLot],
        entityID: UUID,
        entityName: String,
        washSaleAlerts: [WashSaleAlert]
    ) {
        form8949Rows = Form8949Exporter.generateRows(
            lots: lots,
            entityID: entityID,
            taxYear: selectedTaxYear,
            washSaleAlerts: washSaleAlerts
        )
    }

    func exportForm8949CSV(
        lots: [TaxLot],
        entityID: UUID,
        entityName: String,
        washSaleAlerts: [WashSaleAlert]
    ) {
        do {
            let url = try Form8949Exporter.exportToFile(
                lots: lots,
                entityID: entityID,
                entityName: entityName,
                taxYear: selectedTaxYear,
                washSaleAlerts: washSaleAlerts
            )
            exportedFileURL = url
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
        }
    }
}
