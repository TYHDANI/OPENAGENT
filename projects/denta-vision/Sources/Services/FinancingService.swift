import Foundation

/// Manages financing calculations and CareCredit integration
@Observable
final class FinancingService {

    // MARK: - Properties

    private(set) var isCheckingEligibility = false
    private(set) var errorMessage: String? = nil

    // CareCredit API configuration (would be in environment vars in production)
    private let careCreditAPIEndpoint = "https://api.carecredit.com/v1/"

    // Cached eligibility checks to reduce API calls
    private var eligibilityCache = [String: FinancingEligibility]()

    // MARK: - Financing Calculations

    /// Generate financing options for a given amount
    func generateFinancingOptions(for amount: Decimal) -> [FinancingOption] {
        var options: [FinancingOption] = []

        // Always offer cash option
        options.append(
            FinancingOption(
                provider: .cash,
                termMonths: 0,
                monthlyPayment: amount,
                interestRate: 0,
                totalCost: amount,
                downPayment: 0,
                isPromotional: false
            )
        )

        // CareCredit options based on amount
        if amount >= 200 {
            // 6 months no interest
            options.append(
                FinancingOption(
                    provider: .careCredit,
                    termMonths: 6,
                    monthlyPayment: amount / 6,
                    interestRate: 0,
                    totalCost: amount,
                    downPayment: 0,
                    isPromotional: true,
                    promoDetails: "0% APR for 6 months on purchases of $200+"
                )
            )
        }

        if amount >= 500 {
            // 12 months no interest
            options.append(
                FinancingOption(
                    provider: .careCredit,
                    termMonths: 12,
                    monthlyPayment: amount / 12,
                    interestRate: 0,
                    totalCost: amount,
                    downPayment: 0,
                    isPromotional: true,
                    promoDetails: "0% APR for 12 months on purchases of $500+"
                )
            )
        }

        if amount >= 1000 {
            // 18 months no interest
            options.append(
                FinancingOption(
                    provider: .careCredit,
                    termMonths: 18,
                    monthlyPayment: amount / 18,
                    interestRate: 0,
                    totalCost: amount,
                    downPayment: 0,
                    isPromotional: true,
                    promoDetails: "0% APR for 18 months on purchases of $1,000+"
                )
            )

            // 24 months with interest
            let standardRate: Decimal = 0.1499 // 14.99% APR
            let monthlyPayment24 = calculateMonthlyPayment(
                principal: amount,
                annualRate: standardRate,
                months: 24
            )

            options.append(
                FinancingOption(
                    provider: .careCredit,
                    termMonths: 24,
                    monthlyPayment: monthlyPayment24,
                    interestRate: standardRate,
                    totalCost: monthlyPayment24 * 24,
                    downPayment: 0,
                    isPromotional: false
                )
            )
        }

        if amount >= 2500 {
            // 36 and 48 month options
            let standardRate: Decimal = 0.1499

            let monthlyPayment36 = calculateMonthlyPayment(
                principal: amount,
                annualRate: standardRate,
                months: 36
            )

            options.append(
                FinancingOption(
                    provider: .careCredit,
                    termMonths: 36,
                    monthlyPayment: monthlyPayment36,
                    interestRate: standardRate,
                    totalCost: monthlyPayment36 * 36,
                    downPayment: 0,
                    isPromotional: false
                )
            )

            let monthlyPayment48 = calculateMonthlyPayment(
                principal: amount,
                annualRate: standardRate,
                months: 48
            )

            options.append(
                FinancingOption(
                    provider: .careCredit,
                    termMonths: 48,
                    monthlyPayment: monthlyPayment48,
                    interestRate: standardRate,
                    totalCost: monthlyPayment48 * 48,
                    downPayment: 0,
                    isPromotional: false
                )
            )
        }

        // In-house payment plan option
        if amount >= 300 {
            let downPayment = amount * 0.25 // 25% down
            let remainingBalance = amount - downPayment

            options.append(
                FinancingOption(
                    provider: .inHouse,
                    termMonths: 3,
                    monthlyPayment: remainingBalance / 3,
                    interestRate: 0,
                    totalCost: amount,
                    downPayment: downPayment,
                    isPromotional: false,
                    promoDetails: "25% down, balance over 3 months"
                )
            )
        }

        return options
    }

    /// Check patient eligibility for financing
    func checkEligibility(for patient: Patient) async -> FinancingEligibility {
        // Check cache first
        if let cached = eligibilityCache[patient.id.uuidString] {
            let cacheAge = Date().timeIntervalSince(cached.checkedAt)
            if cacheAge < 86400 { // 24 hour cache
                return cached
            }
        }

        isCheckingEligibility = true
        defer { isCheckingEligibility = false }

        // In production, this would make actual API calls to CareCredit
        // For MVP, simulating the response
        let eligibility = await simulateEligibilityCheck(patient: patient)

        // Cache the result
        eligibilityCache[patient.id.uuidString] = eligibility

        return eligibility
    }

    /// Start a financing application
    func startApplication(
        patient: Patient,
        option: FinancingOption,
        amount: Decimal
    ) async -> FinancingApplication {
        // In production, this would initiate the CareCredit application process
        // For MVP, returning a mock application URL

        let application = FinancingApplication(
            id: UUID(),
            provider: option.provider,
            patientId: patient.id,
            requestedAmount: amount,
            status: .pending,
            applicationURL: generateApplicationURL(for: option.provider),
            createdAt: Date()
        )

        return application
    }

    // MARK: - Private Helpers

    private func calculateMonthlyPayment(
        principal: Decimal,
        annualRate: Decimal,
        months: Int
    ) -> Decimal {
        guard annualRate > 0 else {
            return principal / Decimal(months)
        }

        let monthlyRate = annualRate / 12
        let monthsDecimal = Decimal(months)

        // Using the standard loan payment formula
        // M = P * (r(1+r)^n) / ((1+r)^n - 1)
        let onePlusRate = 1 + monthlyRate
        let power = pow(onePlusRate, monthsDecimal)
        let numerator = principal * monthlyRate * power
        let denominator = power - 1

        return numerator / denominator
    }

    private func pow(_ base: Decimal, _ exponent: Decimal) -> Decimal {
        let doubleBase = NSDecimalNumber(decimal: base).doubleValue
        let doubleExponent = NSDecimalNumber(decimal: exponent).doubleValue
        let result = Foundation.pow(doubleBase, doubleExponent)
        return Decimal(result)
    }

    private func simulateEligibilityCheck(patient: Patient) async -> FinancingEligibility {
        // Simulate API delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // For demo purposes, approve most patients
        let isApproved = Int.random(in: 1...100) > 20 // 80% approval

        let creditLimit: Decimal = isApproved ? Decimal.random(in: 1000...10000) : 0
        let availableCredit = creditLimit * 0.8 // Assume 20% utilized

        return FinancingEligibility(
            patientId: patient.id,
            provider: .careCredit,
            isPreApproved: isApproved,
            creditLimit: creditLimit,
            availableCredit: availableCredit,
            checkedAt: Date()
        )
    }

    private func generateApplicationURL(for provider: FinancingProvider) -> URL? {
        switch provider {
        case .careCredit:
            // In production, this would include partner codes and pre-filled data
            return URL(string: "https://www.carecredit.com/apply/?partnerCode=DENTIMATCH")
        case .sunbit:
            return URL(string: "https://sunbit.com/patient/apply?partner=dentimatch")
        case .inHouse:
            return nil // Handled internally
        case .cash:
            return nil
        }
    }
}

// MARK: - Supporting Types

struct FinancingEligibility {
    let patientId: UUID
    let provider: FinancingProvider
    let isPreApproved: Bool
    let creditLimit: Decimal
    let availableCredit: Decimal
    let checkedAt: Date
}

struct FinancingApplication {
    let id: UUID
    let provider: FinancingProvider
    let patientId: UUID
    let requestedAmount: Decimal
    var status: ApplicationStatus
    let applicationURL: URL?
    let createdAt: Date
    var approvedAt: Date?
    var approvedAmount: Decimal?
}

enum ApplicationStatus: String {
    case pending = "Pending"
    case approved = "Approved"
    case declined = "Declined"
    case expired = "Expired"
}

// Decimal extension for random values (demo purposes)
extension Decimal {
    static func random(in range: ClosedRange<Decimal>) -> Decimal {
        let lower = NSDecimalNumber(decimal: range.lowerBound).doubleValue
        let upper = NSDecimalNumber(decimal: range.upperBound).doubleValue
        let random = Double.random(in: lower...upper)
        return Decimal(random)
    }
}