import Foundation
#if canImport(UIKit)
import UIKit
#endif

struct ReportGenerator {

    struct ConsolidatedReport {
        let generatedAt: Date
        let taxYear: Int
        let entities: [EntityReport]
        let totalHoldings: [AssetHolding]
        let totalShortTermGains: Double
        let totalLongTermGains: Double
        let totalEstimatedTax: Double
        let washSaleCount: Int
        let totalDisallowedLoss: Double
    }

    struct EntityReport {
        let entity: LegalEntity
        let accounts: [CustodialAccount]
        let holdings: [AssetHolding]
        let shortTermGains: Double
        let longTermGains: Double
        let estimatedTax: Double
        let washSaleAlerts: [WashSaleAlert]
    }

    struct AssetHolding {
        let asset: String
        let quantity: Double
        let costBasis: Double
    }

    static func generateConsolidated(
        entities: [LegalEntity],
        accounts: [CustodialAccount],
        lots: [TaxLot],
        washSaleAlerts: [WashSaleAlert],
        taxYear: Int
    ) -> ConsolidatedReport {
        var entityReports: [EntityReport] = []

        for entity in entities {
            let entityAccounts = accounts.filter { $0.entityID == entity.id }
            let entityLots = lots.filter { $0.entityID == entity.id }

            // Aggregate holdings
            var holdingsMap: [String: (quantity: Double, costBasis: Double)] = [:]
            for lot in entityLots where !lot.isDisposed {
                let existing = holdingsMap[lot.asset] ?? (0, 0)
                holdingsMap[lot.asset] = (
                    existing.quantity + lot.quantity,
                    existing.costBasis + lot.totalCostBasis
                )
            }
            let holdings = holdingsMap.map { AssetHolding(asset: $0.key, quantity: $0.value.quantity, costBasis: $0.value.costBasis) }
                .sorted { $0.costBasis > $1.costBasis }

            let gains = TaxLotEngine.realizedGains(
                lots: lots,
                entityID: entity.id,
                from: Calendar.current.date(from: DateComponents(year: taxYear, month: 1, day: 1))!,
                to: Calendar.current.date(from: DateComponents(year: taxYear, month: 12, day: 31))!
            )

            let tax = QuarterlyTaxCalculator.estimatedTax(shortTerm: gains.shortTerm, longTerm: gains.longTerm)
            let entityAlerts = washSaleAlerts.filter { $0.saleEntityID == entity.id || $0.buyEntityID == entity.id }

            entityReports.append(EntityReport(
                entity: entity,
                accounts: entityAccounts,
                holdings: holdings,
                shortTermGains: gains.shortTerm,
                longTermGains: gains.longTerm,
                estimatedTax: tax,
                washSaleAlerts: entityAlerts
            ))
        }

        // Total holdings across all entities
        var totalHoldingsMap: [String: (quantity: Double, costBasis: Double)] = [:]
        for report in entityReports {
            for holding in report.holdings {
                let existing = totalHoldingsMap[holding.asset] ?? (0, 0)
                totalHoldingsMap[holding.asset] = (
                    existing.quantity + holding.quantity,
                    existing.costBasis + holding.costBasis
                )
            }
        }
        let totalHoldings = totalHoldingsMap.map { AssetHolding(asset: $0.key, quantity: $0.value.quantity, costBasis: $0.value.costBasis) }
            .sorted { $0.costBasis > $1.costBasis }

        return ConsolidatedReport(
            generatedAt: Date(),
            taxYear: taxYear,
            entities: entityReports,
            totalHoldings: totalHoldings,
            totalShortTermGains: entityReports.reduce(0) { $0 + $1.shortTermGains },
            totalLongTermGains: entityReports.reduce(0) { $0 + $1.longTermGains },
            totalEstimatedTax: entityReports.reduce(0) { $0 + $1.estimatedTax },
            washSaleCount: washSaleAlerts.count,
            totalDisallowedLoss: washSaleAlerts.reduce(0) { $0 + $1.disallowedLoss }
        )
    }

    static func generateTextReport(_ report: ConsolidatedReport) -> String {
        var text = """
        TREASURYPILOT CONSOLIDATED TAX REPORT
        Tax Year: \(report.taxYear)
        Generated: \(ISO8601DateFormatter().string(from: report.generatedAt))
        ═══════════════════════════════════════════════

        SUMMARY
        ───────────────────────────────────────────────
        Total Short-Term Gains/Losses: \(formatCurrency(report.totalShortTermGains))
        Total Long-Term Gains/Losses:  \(formatCurrency(report.totalLongTermGains))
        Total Estimated Tax:           \(formatCurrency(report.totalEstimatedTax))
        Wash Sale Alerts:              \(report.washSaleCount)
        Total Disallowed Losses:       \(formatCurrency(report.totalDisallowedLoss))

        HOLDINGS BY ASSET
        ───────────────────────────────────────────────

        """

        for holding in report.totalHoldings {
            text += "  \(holding.asset): \(String(format: "%.6f", holding.quantity)) (Cost: \(formatCurrency(holding.costBasis)))\n"
        }

        text += "\n"

        for entityReport in report.entities {
            text += """
            ENTITY: \(entityReport.entity.name) (\(entityReport.entity.entityType.rawValue))
            ───────────────────────────────────────────────
              Cost Basis Method: \(entityReport.entity.costBasisMethod.rawValue)
              Tax Treatment: \(entityReport.entity.taxTreatment.rawValue)
              Accounts: \(entityReport.accounts.count)
              Short-Term Gains: \(formatCurrency(entityReport.shortTermGains))
              Long-Term Gains:  \(formatCurrency(entityReport.longTermGains))
              Estimated Tax:    \(formatCurrency(entityReport.estimatedTax))
              Wash Sale Alerts: \(entityReport.washSaleAlerts.count)

              Holdings:

            """

            for holding in entityReport.holdings {
                text += "    \(holding.asset): \(String(format: "%.6f", holding.quantity)) (Cost: \(formatCurrency(holding.costBasis)))\n"
            }
            text += "\n"
        }

        text += """

        ═══════════════════════════════════════════════
        DISCLAIMER: This report is generated for informational purposes only
        and does not constitute tax advice. Consult a qualified tax professional
        before making any tax-related decisions.
        ═══════════════════════════════════════════════
        """

        return text
    }

    static func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(String(format: "%.2f", amount))"
    }
}
