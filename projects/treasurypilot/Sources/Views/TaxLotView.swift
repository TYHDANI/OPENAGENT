import SwiftUI

struct TaxLotView: View {
    @Environment(EntityViewModel.self) private var entityVM
    @Environment(TransactionViewModel.self) private var transactionVM
    @State private var selectedEntityID: UUID?

    private var displayedLots: [TaxLot] {
        let lots = transactionVM.taxLots
        if let entityID = selectedEntityID {
            return lots.filter { $0.entityID == entityID }
        }
        return lots
    }

    private var openLots: [TaxLot] {
        displayedLots.filter { !$0.isDisposed }
    }

    private var disposedLots: [TaxLot] {
        displayedLots.filter { $0.isDisposed }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Entity", selection: $selectedEntityID) {
                        Text("All Entities").tag(nil as UUID?)
                        ForEach(entityVM.entities) { entity in
                            Text(entity.name).tag(entity.id as UUID?)
                        }
                    }
                }

                Section("Open Lots (\(openLots.count))") {
                    if openLots.isEmpty {
                        Text("No open tax lots")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(openLots) { lot in
                            TaxLotRowView(lot: lot)
                        }
                    }
                }

                if !disposedLots.isEmpty {
                    Section("Disposed Lots (\(disposedLots.count))") {
                        ForEach(disposedLots) { lot in
                            TaxLotRowView(lot: lot)
                        }
                    }
                }
            }
            .navigationTitle("Tax Lots")
        }
    }
}

struct TaxLotRowView: View {
    let lot: TaxLot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(lot.asset)
                    .fontWeight(.semibold)
                Spacer()
                Text(String(format: "%.6f", lot.quantity))
                    .font(.subheadline)
            }

            HStack {
                Text("Acquired: \(lot.acquisitionDate, style: .date)")
                Spacer()
                Text(lot.holdingPeriod.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(lot.holdingPeriod == .longTerm ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .clipShape(Capsule())
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack {
                Text("Cost: \(ReportGenerator.formatCurrency(lot.totalCostBasis))")
                Spacer()
                if let gainLoss = lot.gainLoss {
                    Text(gainLoss >= 0 ? "+\(ReportGenerator.formatCurrency(gainLoss))" : ReportGenerator.formatCurrency(gainLoss))
                        .foregroundStyle(gainLoss >= 0 ? .green : .red)
                }
            }
            .font(.caption)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(lot.asset), \(String(format: "%.6f", lot.quantity)) units, \(lot.holdingPeriod.rawValue)")
    }
}
