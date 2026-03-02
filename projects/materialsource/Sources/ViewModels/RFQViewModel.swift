import Foundation
import SwiftUI

/// View model for RFQ management
@Observable
final class RFQViewModel {
    private let rfqService: RFQService
    private let storeManager: StoreManager

    // RFQ form fields
    var quantity = ""
    var unit = "kg"
    var specifications = ""
    var targetDate: Date?
    var includeTargetDate = false

    // State
    var isSubmitting = false
    var errorMessage: String?
    var showingError = false
    var rfqs: [RFQ] = []

    let units = ["kg", "lbs", "sheets", "meters", "feet", "pieces", "tons"]

    init(rfqService: RFQService, storeManager: StoreManager) {
        self.rfqService = rfqService
        self.storeManager = storeManager
    }

    var isProUser: Bool {
        storeManager.isSubscribed
    }

    var groupedRFQs: [(RFQStatus, [RFQ])] {
        let grouped = Dictionary(grouping: rfqs) { $0.status }
        return RFQStatus.allCases.compactMap { status in
            if let rfqs = grouped[status], !rfqs.isEmpty {
                return (status, rfqs)
            }
            return nil
        }
    }

    func createRFQ(
        material: Material,
        supplier: Supplier
    ) async -> Bool {
        guard !quantity.isEmpty else {
            showError("Please enter a quantity")
            return false
        }

        guard let _ = Double(quantity) else {
            showError("Please enter a valid numeric quantity")
            return false
        }

        isSubmitting = true
        errorMessage = nil

        do {
            try await rfqService.createRFQ(
                material: material,
                supplier: supplier,
                quantity: quantity,
                unit: unit,
                specifications: specifications,
                targetDate: includeTargetDate ? targetDate : nil,
                isSubscribed: isProUser
            )

            // Clear form
            quantity = ""
            unit = "kg"
            specifications = ""
            targetDate = nil
            includeTargetDate = false

            isSubmitting = false
            return true
        } catch {
            isSubmitting = false
            showError(error.localizedDescription)
            return false
        }
    }

    func submitRFQ(_ rfq: RFQ) async {
        do {
            try await rfqService.submitRFQ(rfq)
            await loadRFQs()

            // Simulate quote response after delay
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                await rfqService.simulateQuoteResponse(rfq)
                await loadRFQs()
            }
        } catch {
            showError(error.localizedDescription)
        }
    }

    func loadRFQs() async {
        await rfqService.loadRFQs()
        rfqs = rfqService.activeRFQs
    }

    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }

    // Format helpers
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}