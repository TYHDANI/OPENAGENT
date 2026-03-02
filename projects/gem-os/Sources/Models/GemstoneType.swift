import Foundation

/// Supported gemstone types for synthesis simulation
enum GemstoneType: String, CaseIterable, Codable {
    case redBeryl = "Red Beryl"
    case alexandrite = "Alexandrite"
    case tanzanite = "Tanzanite"
    case paraibaTourmaline = "Paraiba Tourmaline"

    var displayName: String {
        rawValue
    }

    var chemicalFormula: String {
        switch self {
        case .redBeryl:
            return "Be₃Al₂(Si₆O₁₈)·Mn"
        case .alexandrite:
            return "BeAl₂O₄·Cr"
        case .tanzanite:
            return "Ca₂Al₃(SiO₄)₃(OH)·V"
        case .paraibaTourmaline:
            return "Na(Li₁.₅Al₁.₅)Al₆(Si₆O₁₈)(BO₃)₃(OH)₃(OH)·Cu"
        }
    }

    var defaultTemperatureRange: ClosedRange<Double> {
        switch self {
        case .redBeryl:
            return 400...600  // °C
        case .alexandrite:
            return 550...800  // °C
        case .tanzanite:
            return 500...700  // °C
        case .paraibaTourmaline:
            return 450...650  // °C
        }
    }

    var defaultPressureRange: ClosedRange<Double> {
        switch self {
        case .redBeryl:
            return 100...300  // MPa
        case .alexandrite:
            return 150...400  // MPa
        case .tanzanite:
            return 200...350  // MPa
        case .paraibaTourmaline:
            return 120...280  // MPa
        }
    }

    var defaultPHRange: ClosedRange<Double> {
        switch self {
        case .redBeryl:
            return 5.5...7.5
        case .alexandrite:
            return 6.0...8.0
        case .tanzanite:
            return 6.5...7.5
        case .paraibaTourmaline:
            return 5.0...7.0
        }
    }
}