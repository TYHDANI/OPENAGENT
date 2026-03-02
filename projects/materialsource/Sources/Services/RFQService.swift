import Foundation
import SwiftData

/// Service for managing RFQ (Request for Quote) operations
@Observable
final class RFQService {
    private let modelContext: ModelContext
    private(set) var activeRFQs: [RFQ] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    /// Free tier limits
    private let freeRFQLimit = 1 // 1 RFQ per month for free users
    private let proRFQLimit = Int.max // Unlimited for Pro users

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Create a new RFQ
    func createRFQ(
        material: Material,
        supplier: Supplier,
        quantity: String,
        unit: String,
        specifications: String,
        targetDate: Date?,
        isSubscribed: Bool
    ) async throws {
        // Check RFQ limit for free users
        if !isSubscribed {
            let monthlyCount = try await getRFQCountForCurrentMonth()
            if monthlyCount >= freeRFQLimit {
                throw RFQError.limitExceeded("Free accounts limited to \(freeRFQLimit) RFQ per month")
            }
        }

        await MainActor.run {
            let rfq = RFQ(
                material: material,
                supplier: supplier,
                quantity: quantity,
                unit: unit,
                specifications: specifications,
                targetDeliveryDate: targetDate
            )

            modelContext.insert(rfq)

            do {
                try modelContext.save()
            } catch {
                errorMessage = "Failed to create RFQ: \(error.localizedDescription)"
            }
        }
    }

    /// Submit an RFQ (simulated for demo)
    func submitRFQ(_ rfq: RFQ) async throws {
        await MainActor.run {
            rfq.status = .submitted
            rfq.lastUpdatedDate = Date()

            // Simulate submission delay
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

                await MainActor.run {
                    rfq.status = .pending
                    rfq.lastUpdatedDate = Date()

                    do {
                        try modelContext.save()
                    } catch {
                        print("Failed to update RFQ status: \(error)")
                    }
                }
            }

            do {
                try modelContext.save()
            } catch {
                errorMessage = "Failed to submit RFQ: \(error.localizedDescription)"
                throw error
            }
        }
    }

    /// Get all RFQs for the current user
    func loadRFQs() async {
        isLoading = true
        errorMessage = nil

        await MainActor.run {
            do {
                var descriptor = FetchDescriptor<RFQ>()
                descriptor.sortBy = [SortDescriptor(\.submittedDate, order: .reverse)]
                activeRFQs = try modelContext.fetch(descriptor)
            } catch {
                errorMessage = "Failed to load RFQs: \(error.localizedDescription)"
                activeRFQs = []
            }

            isLoading = false
        }
    }

    /// Get RFQs by status
    func getRFQsByStatus(_ status: RFQStatus) async -> [RFQ] {
        await MainActor.run {
            do {
                var descriptor = FetchDescriptor<RFQ>()
                descriptor.predicate = #Predicate<RFQ> { rfq in
                    rfq.status == status
                }
                descriptor.sortBy = [SortDescriptor(\.submittedDate, order: .reverse)]
                return try modelContext.fetch(descriptor)
            } catch {
                return []
            }
        }
    }

    /// Update RFQ with quote (simulated)
    func simulateQuoteResponse(_ rfq: RFQ) async {
        await MainActor.run {
            // Generate a mock quote
            let basePrice = Double.random(in: 50...500)
            let quantity = Double(rfq.quantity) ?? 1.0
            let quote = Quote(
                unitPrice: basePrice,
                totalPrice: basePrice * quantity,
                currency: "USD",
                leadTime: rfq.supplier.leadTimeRange,
                validUntil: Date().addingTimeInterval(30 * 24 * 60 * 60), // 30 days
                termsAndConditions: "Standard terms apply. Prices subject to change."
            )

            rfq.quoteReceived = quote
            rfq.status = .quoted
            rfq.lastUpdatedDate = Date()

            do {
                try modelContext.save()
            } catch {
                errorMessage = "Failed to update quote: \(error.localizedDescription)"
            }
        }
    }

    /// Get RFQ count for current month (for limit checking)
    private func getRFQCountForCurrentMonth() async throws -> Int {
        await MainActor.run {
            let calendar = Calendar.current
            let now = Date()
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now

            var descriptor = FetchDescriptor<RFQ>()
            descriptor.predicate = #Predicate<RFQ> { rfq in
                rfq.submittedDate >= startOfMonth
            }

            do {
                return try modelContext.fetchCount(descriptor)
            } catch {
                throw error
            }
        }
    }

    /// Compare quotes from multiple suppliers
    func compareQuotes(for material: Material) async -> [SupplierComparison] {
        await MainActor.run {
            do {
                var descriptor = FetchDescriptor<RFQ>()
                descriptor.predicate = #Predicate<RFQ> { rfq in
                    rfq.material.id == material.id && rfq.status == .quoted
                }

                let rfqs = try modelContext.fetch(descriptor)

                return rfqs.compactMap { rfq in
                    guard let quote = rfq.quoteReceived else { return nil }
                    return SupplierComparison(
                        supplier: rfq.supplier,
                        unitPrice: quote.unitPrice,
                        leadTime: quote.leadTime,
                        minimumOrder: rfq.supplier.minimumOrderQuantity,
                        certifications: rfq.supplier.certifications
                    )
                }.sorted { $0.unitPrice < $1.unitPrice }
            } catch {
                return []
            }
        }
    }
}

enum RFQError: LocalizedError {
    case limitExceeded(String)

    var errorDescription: String? {
        switch self {
        case .limitExceeded(let message):
            return message
        }
    }
}

/// Structure for supplier comparison
struct SupplierComparison: Identifiable {
    let id = UUID()
    let supplier: Supplier
    let unitPrice: Double
    let leadTime: String
    let minimumOrder: String
    let certifications: [String]
}