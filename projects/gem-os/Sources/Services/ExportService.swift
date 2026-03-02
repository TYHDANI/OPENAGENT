import Foundation
#if canImport(UIKit)
import UIKit
#endif
import UniformTypeIdentifiers

/// Service for exporting simulation results to PDF and CSV formats
final class ExportService {
    static let shared = ExportService()

    private init() {}

    // MARK: - CSV Export

    /// Export simulation result to CSV format
    func exportToCSV(result: SimulationResult) -> URL? {
        let fileName = "gemos_simulation_\(DateFormatter.fileNameFormatter.string(from: result.timestamp)).csv"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        let csvContent = """
        GEM OS Simulation Results
        Generated: \(DateFormatter.fullFormatter.string(from: result.timestamp))

        PARAMETERS
        Parameter,Value
        Gemstone Type,\(result.parameters.gemstoneType.displayName)
        Temperature (°C),\(result.parameters.temperature)
        Pressure (MPa),\(result.parameters.pressure)
        pH,\(result.parameters.pH)
        Duration (hours),\(result.parameters.duration)
        Seed Crystal Size (mm),\(result.parameters.seedCrystalSize)
        Nutrient Concentration (mol/L),\(result.parameters.nutrientConcentration)
        Cooling Rate (°C/hour),\(result.parameters.coolingRate)

        RESULTS
        Metric,Value
        Crystal Yield (g),\(result.crystalYield)
        Average Size (mm),\(result.averageSize)
        Clarity (0-1),\(result.clarity)
        Color Saturation (0-1),\(result.colorSaturation)
        Defect Density (per mm³),\(result.defectDensity)
        Overall Quality,\(result.overallQuality)
        Success Probability,\(result.successProbability)

        SIMULATION INFO
        Monte Carlo Iterations,\(result.iterations)
        Simulation Time (seconds),\(result.simulationTime)
        """

        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error writing CSV: \(error)")
            return nil
        }
    }

    /// Export multiple simulation results to CSV
    func exportToCSV(results: [SimulationResult]) -> URL? {
        let fileName = "gemos_simulations_batch_\(DateFormatter.fileNameFormatter.string(from: Date())).csv"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        var csvContent = """
        GEM OS Batch Simulation Results
        Generated: \(DateFormatter.fullFormatter.string(from: Date()))
        Total Simulations: \(results.count)

        Timestamp,Gemstone,Temperature,Pressure,pH,Duration,Yield,Size,Quality,Success Rate,Iterations
        """

        for result in results {
            csvContent += "\n"
            csvContent += [
                DateFormatter.shortFormatter.string(from: result.timestamp),
                result.parameters.gemstoneType.displayName,
                String(format: "%.0f", result.parameters.temperature),
                String(format: "%.0f", result.parameters.pressure),
                String(format: "%.1f", result.parameters.pH),
                String(format: "%.0f", result.parameters.duration),
                String(format: "%.2f", result.crystalYield),
                String(format: "%.1f", result.averageSize),
                String(format: "%.2f", result.overallQuality),
                String(format: "%.1f%%", result.successProbability * 100),
                String(result.iterations)
            ].joined(separator: ",")
        }

        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error writing batch CSV: \(error)")
            return nil
        }
    }

    // MARK: - PDF Export

    #if canImport(UIKit)
    /// Export simulation result to PDF format
    func exportToPDF(result: SimulationResult) -> URL? {
        let fileName = "gemos_report_\(DateFormatter.fileNameFormatter.string(from: result.timestamp)).pdf"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))

        do {
            try pdfRenderer.writePDF(to: fileURL) { context in
                context.beginPage()
                drawPDFContent(for: result, in: context)
            }
            return fileURL
        } catch {
            print("Error creating PDF: \(error)")
            return nil
        }
    }

    private func drawPDFContent(for result: SimulationResult, in context: UIGraphicsPDFRendererContext) {
        let pageRect = context.format.bounds
        var yPosition: CGFloat = 50

        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]
        let title = "GEM OS Simulation Report"
        title.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: titleAttributes)
        yPosition += 40

        // Date and gemstone
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.darkGray
        ]
        let subtitle = "\(result.parameters.gemstoneType.displayName) - \(DateFormatter.fullFormatter.string(from: result.timestamp))"
        subtitle.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: subtitleAttributes)
        yPosition += 30

        // Separator
        UIColor.lightGray.setStroke()
        let separatorPath = UIBezierPath()
        separatorPath.move(to: CGPoint(x: 50, y: yPosition))
        separatorPath.addLine(to: CGPoint(x: pageRect.width - 50, y: yPosition))
        separatorPath.lineWidth = 0.5
        separatorPath.stroke()
        yPosition += 20

        // Section headers attributes
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]

        // Parameters Section
        "Synthesis Parameters".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionAttributes)
        yPosition += 25

        let parameters = [
            ("Temperature", "\(Int(result.parameters.temperature))°C"),
            ("Pressure", "\(Int(result.parameters.pressure)) MPa"),
            ("pH", String(format: "%.1f", result.parameters.pH)),
            ("Duration", "\(Int(result.parameters.duration)) hours"),
            ("Seed Crystal Size", String(format: "%.1f mm", result.parameters.seedCrystalSize)),
            ("Nutrient Concentration", String(format: "%.2f mol/L", result.parameters.nutrientConcentration)),
            ("Cooling Rate", String(format: "%.1f°C/hour", result.parameters.coolingRate))
        ]

        for (label, value) in parameters {
            drawLabelValue(label: label, value: value, at: CGPoint(x: 70, y: yPosition),
                          labelAttributes: labelAttributes, valueAttributes: valueAttributes)
            yPosition += 20
        }

        yPosition += 20

        // Results Section
        "Simulation Results".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionAttributes)
        yPosition += 25

        let results = [
            ("Crystal Yield", String(format: "%.2f g", result.crystalYield)),
            ("Average Crystal Size", String(format: "%.1f mm", result.averageSize)),
            ("Clarity", String(format: "%.2f (%.0f%%)", result.clarity, result.clarity * 100)),
            ("Color Saturation", String(format: "%.2f (%.0f%%)", result.colorSaturation, result.colorSaturation * 100)),
            ("Defect Density", String(format: "%.1f per mm³", result.defectDensity)),
            ("Overall Quality", String(format: "%.2f (%.0f%%)", result.overallQuality, result.overallQuality * 100)),
            ("Success Probability", String(format: "%.1f%%", result.successProbability * 100))
        ]

        for (label, value) in results {
            drawLabelValue(label: label, value: value, at: CGPoint(x: 70, y: yPosition),
                          labelAttributes: labelAttributes, valueAttributes: valueAttributes)
            yPosition += 20
        }

        yPosition += 20

        // Simulation Info
        "Simulation Information".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionAttributes)
        yPosition += 25

        let simInfo = [
            ("Monte Carlo Iterations", "\(result.iterations)"),
            ("Simulation Time", String(format: "%.2f seconds", result.simulationTime))
        ]

        for (label, value) in simInfo {
            drawLabelValue(label: label, value: value, at: CGPoint(x: 70, y: yPosition),
                          labelAttributes: labelAttributes, valueAttributes: valueAttributes)
            yPosition += 20
        }

        // Footer
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray
        ]
        let footer = "Generated by GEM OS - Professional Gemstone Synthesis Simulation"
        let footerSize = footer.size(withAttributes: footerAttributes)
        footer.draw(at: CGPoint(x: (pageRect.width - footerSize.width) / 2, y: pageRect.height - 50),
                   withAttributes: footerAttributes)
    }

    private func drawLabelValue(label: String, value: String, at point: CGPoint,
                               labelAttributes: [NSAttributedString.Key: Any],
                               valueAttributes: [NSAttributedString.Key: Any]) {
        label.draw(at: point, withAttributes: labelAttributes)
        value.draw(at: CGPoint(x: point.x + 200, y: point.y), withAttributes: valueAttributes)
    }
    #else
    /// Stub for non-UIKit platforms (macOS tests)
    func exportToPDF(result: SimulationResult) -> URL? { nil }
    #endif
}

// MARK: - DateFormatter Extensions

private extension DateFormatter {
    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()

    static let fullFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .medium
        return formatter
    }()

    static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
}