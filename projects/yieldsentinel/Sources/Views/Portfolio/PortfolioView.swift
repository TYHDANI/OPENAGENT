import SwiftUI

struct PortfolioView: View {
    @Bindable var viewModel: PortfolioViewModel
    let products: [YieldProduct]

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Summary
                if let summary = viewModel.summary, summary.positionCount > 0 {
                    Section {
                        VStack(spacing: 12) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Total Value")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(summary.formattedTotal)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Risk Score")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    ScoreGaugeView(score: Int(summary.weightedRiskScore), size: 56)
                                }
                            }

                            HStack {
                                Label("\(summary.positionCount) positions", systemImage: "chart.pie")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // MARK: - Concentration Warnings
                    if !summary.concentrationWarnings.isEmpty {
                        Section("Warnings") {
                            ForEach(summary.concentrationWarnings) { warning in
                                HStack(spacing: 10) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(warning.productName)
                                            .font(.subheadline.bold())
                                        Text(warning.message)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                // MARK: - Rebalance Suggestions
                if !viewModel.rebalanceSuggestions.isEmpty {
                    Section("Rebalance Suggestions") {
                        ForEach(viewModel.rebalanceSuggestions) { suggestion in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(suggestion.productName)
                                    .font(.subheadline.bold())

                                HStack {
                                    Text(String(format: "%.0f%%", suggestion.currentAllocation))
                                        .foregroundStyle(.red)
                                    Image(systemName: "arrow.right")
                                        .font(.caption)
                                    Text(String(format: "%.0f%%", suggestion.suggestedAllocation))
                                        .foregroundStyle(.green)
                                }
                                .font(.caption.bold().monospaced())

                                Text(suggestion.reason)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                // MARK: - Positions
                Section {
                    if viewModel.positions.isEmpty {
                        ContentUnavailableView(
                            "No Positions",
                            systemImage: "chart.bar.doc.horizontal",
                            description: Text("Add your yield positions to track aggregate risk.")
                        )
                    } else {
                        ForEach(viewModel.positions) { position in
                            PositionRowView(position: position, product: products.first(where: { $0.id == position.productID }))
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.removePosition(viewModel.positions[index].id)
                            }
                            viewModel.computeSummary(products: products)
                        }
                    }
                } header: {
                    HStack {
                        Text("Positions")
                        Spacer()
                        Button("Add", systemImage: "plus") {
                            viewModel.showingAddPosition = true
                        }
                        .font(.caption)
                    }
                }
            }
            .navigationTitle("Portfolio")
            .sheet(isPresented: $viewModel.showingAddPosition) {
                AddPositionSheet(viewModel: viewModel, products: products)
            }
            .onAppear {
                viewModel.loadPositions(products: products)
            }
        }
    }
}

// MARK: - Position Row

private struct PositionRowView: View {
    let position: PortfolioPosition
    let product: YieldProduct?

    var body: some View {
        HStack(spacing: 12) {
            if let product {
                ScoreGaugeView(score: product.sentinelScore, size: 36)
            } else {
                Image(systemName: "questionmark.circle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 36)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(position.productName)
                    .font(.subheadline.bold())

                if let product {
                    HStack(spacing: 6) {
                        RiskBadge(level: product.riskLevel)
                        Text(product.formattedAPY)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(position.formattedAmount)
                    .font(.subheadline.bold())

                Text(position.entryDate, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Add Position Sheet

private struct AddPositionSheet: View {
    @Bindable var viewModel: PortfolioViewModel
    let products: [YieldProduct]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Protocol") {
                    Picker("Select Protocol", selection: $viewModel.newProductID) {
                        Text("Select...").tag("")
                        ForEach(products) { product in
                            Text("\(product.name) (Score: \(product.sentinelScore))")
                                .tag(product.id)
                        }
                    }
                    .onChange(of: viewModel.newProductID) { _, newID in
                        if let product = products.first(where: { $0.id == newID }) {
                            viewModel.newProductName = product.name
                        }
                    }
                }

                Section("Position") {
                    TextField("Amount (USD)", text: $viewModel.newAmountText)
                        .keyboardType(.decimalPad)

                    TextField("Notes (optional)", text: $viewModel.newNotes)
                }
            }
            .navigationTitle("Add Position")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addPositionFromForm()
                        viewModel.computeSummary(products: products)
                        dismiss()
                    }
                    .disabled(viewModel.newProductID.isEmpty || Double(viewModel.newAmountText) == nil)
                }
            }
        }
    }
}
