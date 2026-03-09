import SwiftUI

struct ReportsView: View {
    @Environment(EntityViewModel.self) private var entityVM
    @Environment(TransactionViewModel.self) private var transactionVM
    @Environment(TaxViewModel.self) private var taxVM
    @Environment(StoreManager.self) private var storeManager
    @State private var reportVM = ReportViewModel()
    @State private var showShareSheet = false
    @State private var selectedEntityForExport: LegalEntity?

    var body: some View {
        NavigationStack {
            List {
                Section("Consolidated Report") {
                    Button {
                        reportVM.generateConsolidatedReport(
                            entities: entityVM.entities,
                            accounts: entityVM.accounts,
                            lots: transactionVM.taxLots,
                            washSaleAlerts: taxVM.washSaleAlerts
                        )
                    } label: {
                        Label("Generate Report", systemImage: "doc.text.magnifyingglass")
                    }

                    if !reportVM.reportText.isEmpty {
                        NavigationLink {
                            ReportDetailView(reportText: reportVM.reportText)
                        } label: {
                            Label("View Report", systemImage: "doc.text")
                        }
                    }

                    if let report = reportVM.consolidatedReport {
                        LabeledContent("Total Short-Term", value: ReportGenerator.formatCurrency(report.totalShortTermGains))
                        LabeledContent("Total Long-Term", value: ReportGenerator.formatCurrency(report.totalLongTermGains))
                        LabeledContent("Estimated Tax", value: ReportGenerator.formatCurrency(report.totalEstimatedTax))
                    }
                }

                Section("Form 8949 Export") {
                    if !storeManager.currentTier.canExport {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.orange)
                            Text("Upgrade to Professional or higher to export Form 8949 data.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    ForEach(entityVM.entities) { entity in
                        Button {
                            reportVM.exportForm8949CSV(
                                lots: transactionVM.taxLots,
                                entityID: entity.id,
                                entityName: entity.name,
                                washSaleAlerts: taxVM.washSaleAlerts
                            )
                        } label: {
                            Label("Export \(entity.name)", systemImage: "tablecells")
                        }
                        .disabled(!storeManager.currentTier.canExport)
                    }

                    if let url = reportVM.exportedFileURL {
                        ShareLink(item: url) {
                            Label("Share Last Export", systemImage: "square.and.arrow.up")
                        }
                    }
                }

                Section("Quarterly Estimates") {
                    @Bindable var tvm = taxVM
                    Picker("Tax Year", selection: $tvm.selectedTaxYear) {
                        let currentYear = Calendar.current.component(.year, from: Date())
                        ForEach((currentYear - 2)...(currentYear), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }

                    Button {
                        Task {
                            await taxVM.calculateEstimates(
                                entities: entityVM.entities,
                                lots: transactionVM.taxLots
                            )
                        }
                    } label: {
                        Label("Recalculate Estimates", systemImage: "arrow.clockwise")
                    }

                    ForEach(entityVM.entities) { entity in
                        let estimates = taxVM.estimates(for: entity.id)
                        if !estimates.isEmpty {
                            DisclosureGroup(entity.name) {
                                ForEach(estimates) { est in
                                    HStack {
                                        Text(est.quarter.rawValue)
                                        Spacer()
                                        VStack(alignment: .trailing) {
                                            Text(ReportGenerator.formatCurrency(est.estimatedTaxOwed))
                                                .fontWeight(.medium)
                                            Text("Due: \(est.quarter.estimatedPaymentDeadline)")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .font(.subheadline)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Reports")
        }
    }
}

struct ReportDetailView: View {
    let reportText: String

    var body: some View {
        ScrollView {
            Text(reportText)
                .font(.system(.caption, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Consolidated Report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ShareLink(item: reportText) {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
}
