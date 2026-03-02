import Foundation

/// Represents a treatment case presentation with financing options
struct CasePresentation: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    var title: String
    var treatments: [Treatment]
    var totalCost: Decimal
    var insuranceEstimate: Decimal
    var outOfPocketCost: Decimal
    var financingOptions: [FinancingOption]
    var presentationDate: Date
    var acceptedDate: Date?
    var status: CaseStatus
    var notes: String

    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        patientId: UUID,
        title: String,
        treatments: [Treatment] = [],
        totalCost: Decimal = 0,
        insuranceEstimate: Decimal = 0,
        financingOptions: [FinancingOption] = [],
        status: CaseStatus = .draft,
        notes: String = ""
    ) {
        self.id = id
        self.patientId = patientId
        self.title = title
        self.treatments = treatments
        self.totalCost = totalCost
        self.insuranceEstimate = insuranceEstimate
        self.outOfPocketCost = totalCost - insuranceEstimate
        self.financingOptions = financingOptions
        self.presentationDate = Date()
        self.status = status
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Calculate financing options based on out-of-pocket cost
    mutating func generateFinancingOptions() {
        financingOptions = []

        // CareCredit options
        if outOfPocketCost > 200 {
            // 6 months no interest
            financingOptions.append(
                FinancingOption(
                    provider: .careCredit,
                    termMonths: 6,
                    monthlyPayment: outOfPocketCost / 6,
                    interestRate: 0,
                    totalCost: outOfPocketCost
                )
            )

            // 12 months no interest for amounts over $1000
            if outOfPocketCost > 1000 {
                financingOptions.append(
                    FinancingOption(
                        provider: .careCredit,
                        termMonths: 12,
                        monthlyPayment: outOfPocketCost / 12,
                        interestRate: 0,
                        totalCost: outOfPocketCost
                    )
                )
            }

            // 24 months with interest
            let interestRate: Decimal = 0.1499 // 14.99% APR
            let monthlyRate = interestRate / 12
            let totalMonths: Decimal = 24
            let monthlyPayment = calculateMonthlyPayment(
                principal: outOfPocketCost,
                monthlyRate: monthlyRate,
                months: totalMonths
            )

            financingOptions.append(
                FinancingOption(
                    provider: .careCredit,
                    termMonths: 24,
                    monthlyPayment: monthlyPayment,
                    interestRate: interestRate,
                    totalCost: monthlyPayment * totalMonths
                )
            )
        }

        // In-house payment plan (simple division)
        if outOfPocketCost > 500 {
            financingOptions.append(
                FinancingOption(
                    provider: .inHouse,
                    termMonths: 3,
                    monthlyPayment: outOfPocketCost / 3,
                    interestRate: 0,
                    totalCost: outOfPocketCost,
                    downPayment: outOfPocketCost * 0.3 // 30% down
                )
            )
        }
    }

    /// Calculate monthly payment with interest
    private func calculateMonthlyPayment(principal: Decimal, monthlyRate: Decimal, months: Decimal) -> Decimal {
        if monthlyRate == 0 {
            return principal / months
        }
        let power = pow(1 + monthlyRate, months)
        return principal * (monthlyRate * power) / (power - 1)
    }
}

/// Financing option details
struct FinancingOption: Codable, Identifiable {
    let id: UUID
    var provider: FinancingProvider
    var termMonths: Int
    var monthlyPayment: Decimal
    var interestRate: Decimal
    var totalCost: Decimal
    var downPayment: Decimal
    var isPromotional: Bool
    var promoDetails: String?

    init(
        id: UUID = UUID(),
        provider: FinancingProvider,
        termMonths: Int,
        monthlyPayment: Decimal,
        interestRate: Decimal = 0,
        totalCost: Decimal,
        downPayment: Decimal = 0,
        isPromotional: Bool = false,
        promoDetails: String? = nil
    ) {
        self.id = id
        self.provider = provider
        self.termMonths = termMonths
        self.monthlyPayment = monthlyPayment
        self.interestRate = interestRate
        self.totalCost = totalCost
        self.downPayment = downPayment
        self.isPromotional = isPromotional
        self.promoDetails = promoDetails
    }
}

/// Financing providers
enum FinancingProvider: String, Codable, CaseIterable {
    case careCredit = "CareCredit"
    case sunbit = "Sunbit"
    case inHouse = "In-House"
    case cash = "Cash"
}

/// Case presentation status
enum CaseStatus: String, Codable, CaseIterable {
    case draft = "Draft"
    case presented = "Presented"
    case accepted = "Accepted"
    case declined = "Declined"
    case partiallyAccepted = "Partially Accepted"
    case expired = "Expired"
}

// Helper for Decimal power calculation
private func pow(_ base: Decimal, _ exponent: Decimal) -> Decimal {
    // For financial calculations, we can use Double conversion
    // This is acceptable for monthly payment calculations
    let doubleBase = NSDecimalNumber(decimal: base).doubleValue
    let doubleExponent = NSDecimalNumber(decimal: exponent).doubleValue
    let result = Foundation.pow(doubleBase, doubleExponent)
    return Decimal(result)
}