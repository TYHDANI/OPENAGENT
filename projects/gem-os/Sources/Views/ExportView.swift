import SwiftUI

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var storeManager
    let result: SimulationResult
    @State private var selectedFormat: ExportFormat = .pdf
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    @State private var errorMessage: String?

    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case csv = "CSV"

        var icon: String {
            switch self {
            case .pdf: return "doc.richtext"
            case .csv: return "tablecells"
            }
        }

        var description: String {
            switch self {
            case .pdf: return "Professional report format with charts and formatting"
            case .csv: return "Spreadsheet-compatible format for data analysis"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // MARK: - Result Preview
                ResultPreviewCard(result: result)

                // MARK: - Format Selection
                VStack(alignment: .leading, spacing: 16) {
                    Label("Export Format", systemImage: "doc.badge.arrow.up")
                        .font(.headline)

                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        FormatOption(
                            format: format,
                            isSelected: selectedFormat == format,
                            isLocked: !storeManager.isSubscribed,
                            onSelect: {
                                if storeManager.isSubscribed {
                                    selectedFormat = format
                                }
                            }
                        )
                    }
                }
                .padding()
                .background(Color.secondaryGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Spacer()

                // MARK: - Export Button
                VStack(spacing: 12) {
                    if !storeManager.isSubscribed {
                        Label("Premium subscription required for export", systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button(action: exportResult) {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                            Text(isExporting ? "Exporting..." : "Export \(selectedFormat.rawValue)")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(storeManager.isSubscribed ? Color.accentColor : Color.gray)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isExporting || !storeManager.isSubscribed)

                    if let error = errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding()
            .navigationTitle("Export Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            #if canImport(UIKit)
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            #endif
        }
    }

    // MARK: - Export

    private func exportResult() {
        isExporting = true
        errorMessage = nil

        Task {
            await MainActor.run {
                switch selectedFormat {
                case .pdf:
                    exportURL = ExportService.shared.exportToPDF(result: result)
                case .csv:
                    exportURL = ExportService.shared.exportToCSV(result: result)
                }

                isExporting = false

                if exportURL != nil {
                    showingShareSheet = true
                } else {
                    errorMessage = "Failed to export file"
                }
            }
        }
    }
}

// MARK: - Result Preview Card

struct ResultPreviewCard: View {
    let result: SimulationResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Simulation Summary", systemImage: "doc.text.magnifyingglass")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(result.parameters.gemstoneType.displayName, systemImage: "rhombus.fill")
                        .font(.subheadline)
                    Spacer()
                    Text(result.timestamp, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                Grid(alignment: .leading, horizontalSpacing: 40, verticalSpacing: 8) {
                    GridRow {
                        PreviewMetric(label: "Yield", value: String(format: "%.2f g", result.crystalYield))
                        PreviewMetric(label: "Quality", value: String(format: "%.0f%%", result.overallQuality * 100))
                    }
                    GridRow {
                        PreviewMetric(label: "Iterations", value: "\(result.iterations)")
                        PreviewMetric(label: "Success", value: String(format: "%.0f%%", result.successProbability * 100))
                    }
                }
            }
        }
        .padding()
        .background(Color.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview Metric

struct PreviewMetric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Format Option

struct FormatOption: View {
    let format: ExportView.ExportFormat
    let isSelected: Bool
    let isLocked: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: format.icon)
                    .font(.title2)
                    .foregroundStyle(isLocked ? Color.secondary : (isSelected ? Color.accentColor : Color.primary))
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(format.rawValue)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                    Text(format.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isLocked ? Color.tertiaryGroupedBackground.opacity(0.5) :
                          (isSelected ? Color.accentColor.opacity(0.1) : Color.tertiaryGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected && !isLocked ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }
}

// MARK: - Share Sheet

#if canImport(UIKit)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

#Preview {
    ExportView(result: SimulationResult(
        id: UUID(),
        timestamp: Date(),
        parameters: SynthesisParameters(gemstoneType: .redBeryl),
        iterations: 10_000,
        crystalYield: 1.23,
        averageSize: 12.5,
        clarity: 0.85,
        colorSaturation: 0.92,
        defectDensity: 23.5,
        successProbability: 0.78,
        simulationTime: 12.5
    ))
    .environment(StoreManager())
}